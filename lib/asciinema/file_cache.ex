defmodule Asciinema.FileCache do
  use GenServer
  require Logger

  @default_get_path_timeout 5_000

  defmodule Error do
    defexception [:type, :bucket, :key, :reason, :kind, :stacktrace]

    @impl true
    def message(%__MODULE__{} = error) do
      base =
        "file cache #{error.type} for #{inspect(error.bucket)} #{inspect(error.key)}"

      base <> ": " <> format_reason(error)
    end

    defp format_reason(%__MODULE__{kind: :error, reason: exception}) when is_struct(exception) do
      Exception.message(exception)
    end

    defp format_reason(%__MODULE__{kind: kind, reason: reason}) when not is_nil(kind) do
      "#{kind}: #{inspect(reason)}"
    end

    defp format_reason(%__MODULE__{reason: reason}) do
      inspect(reason)
    end
  end

  def start_link(opts) when is_list(opts) do
    base_path = Keyword.fetch!(opts, :path)
    buckets = Keyword.get(opts, :buckets, [])
    collect_interval = Keyword.get(opts, :collect_interval, :midnight)

    init_arg = %{
      base_path: base_path,
      buckets: buckets,
      collect_interval: normalize_collect_interval(collect_interval)
    }

    GenServer.start_link(__MODULE__, init_arg, Keyword.take(opts, [:name]))
  end

  def get_path(bucket, key, fun) do
    get_path(__MODULE__, bucket, key, fun)
  end

  def get_path(bucket, key, fun, timeout) when is_function(fun, 1) do
    get_path(__MODULE__, bucket, key, fun, timeout)
  end

  def get_path(server, bucket, key, fun) do
    get_path(server, bucket, key, fun, @default_get_path_timeout)
  end

  def get_path(server, bucket, key, fun, timeout) do
    case fetch_path(server, bucket, key, fun, timeout) do
      {:ok, path} ->
        path

      {:error, error} ->
        raise error
    end
  end

  def fetch_path(bucket, key, fun) do
    fetch_path(__MODULE__, bucket, key, fun)
  end

  def fetch_path(bucket, key, fun, timeout) when is_function(fun, 1) do
    fetch_path(__MODULE__, bucket, key, fun, timeout)
  end

  def fetch_path(server, bucket, key, fun) do
    fetch_path(server, bucket, key, fun, @default_get_path_timeout)
  end

  def fetch_path(server, bucket, key, fun, timeout) do
    try do
      case GenServer.call(server, {:get_path, bucket, key, fun}, timeout) do
        {:ok, path} ->
          {:ok, path}

        {:error, reason} ->
          {:error, to_error(bucket, key, reason)}
      end
    catch
      :exit, {:timeout, {GenServer, :call, _}} ->
        {:error, to_error(bucket, key, {:timeout, timeout})}
    end
  end

  @impl true
  def init(%{
        base_path: base_path,
        buckets: buckets,
        collect_interval: collect_interval
      }) do
    schedule_collect(collect_interval)

    if !System.find_executable("fd") do
      Logger.warning("fd executable not found in PATH, required for file cache cleanup")
    end

    state = %{
      base_path: base_path,
      buckets: init_buckets(buckets),
      task_refs: %{},
      collect_interval: collect_interval
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get_path, bucket, key, generator}, from, state) do
    path = Path.join([to_string(bucket), sharded_path(key_hash(key))])

    case get_in(state, [:buckets, bucket, :inflight, path]) do
      nil ->
        full_path = full_path(state.base_path, path)

        if File.exists?(full_path) do
          Logger.debug("cache hit for #{path}")
          :ok = File.touch(full_path)

          {:reply, {:ok, full_path}, state}
        else
          Logger.debug("cache miss for #{path}, calling generator")
          task_ref = generate_async(state.base_path, path, generator)

          state =
            state
            |> put_in([:buckets, bucket, :inflight, path], [from])
            |> put_in([:task_refs, task_ref], {bucket, path})

          {:noreply, state}
        end

      waiters ->
        Logger.debug("cache miss for #{path}, joining other waiters")
        {:noreply, put_in(state, [:buckets, bucket, :inflight, path], [from | waiters])}
    end
  end

  @impl true
  def handle_cast({:prune, candidates}, state) do
    prune(candidates)

    {:noreply, state}
  end

  @impl true
  def handle_info(:collect, state) do
    bucket_ttls = Enum.map(state.buckets, fn {bucket, %{ttl: ttl}} -> {bucket, ttl} end)
    :ok = collect_async(self(), state.base_path, bucket_ttls)
    schedule_collect(state.collect_interval)

    {:noreply, state}
  end

  @impl true
  def handle_info({ref, result}, state) when is_reference(ref) do
    {{bucket, path}, task_refs} = Map.pop(state.task_refs, ref)
    Process.demonitor(ref, [:flush])
    state = %{state | task_refs: task_refs}

    {:noreply, reply_waiters(state, bucket, path, result)}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    {{bucket, path}, task_refs} = Map.pop(state.task_refs, ref)
    Logger.error("file cache generator task crashed for #{bucket}/#{path}: #{inspect(reason)}")
    state = %{state | task_refs: task_refs}
    reply = {:error, {:task_crash, reason}}

    {:noreply, reply_waiters(state, bucket, path, reply)}
  end

  @doc false
  def generate(base_path, path, generator) do
    full_path = full_path(base_path, path)
    tmp_path = full_path <> ".tmp"

    try do
      :ok = File.mkdir_p(Path.dirname(full_path))
      :ok = generator.(tmp_path)
      :ok = File.rename(tmp_path, full_path)
      {:ok, full_path}
    rescue
      exception ->
        _ = File.rm(tmp_path)
        {:error, {:generator_failed, :error, exception, __STACKTRACE__}}
    catch
      kind, reason ->
        _ = File.rm(tmp_path)
        {:error, {:generator_failed, kind, reason, __STACKTRACE__}}
    end
  end

  def collect(base_path, buckets) do
    buckets
    |> Enum.map(&collect_bucket(base_path, &1))
    |> Enum.flat_map(& &1)
  end

  @doc false
  def collect_and_cast(server, base_path, buckets) do
    candidates = collect(base_path, buckets)
    GenServer.cast(server, {:prune, candidates})
  end

  defp collect_bucket(base_path, {bucket, ttl_seconds}) do
    bucket_path = full_path(base_path, to_string(bucket))
    cutoff = System.os_time(:second) - ttl_seconds

    if File.dir?(bucket_path) do
      collect_candidates_with_fd(bucket_path, cutoff)
    else
      []
    end
  end

  def prune(candidates) do
    Enum.each(candidates, &prune_file/1)
  end

  defp prune_file({full_path, cutoff}) do
    case File.stat(full_path, time: :posix) do
      {:ok, %File.Stat{mtime: mtime}} when mtime < cutoff ->
        _ = File.rm(full_path)
        :ok

      _ ->
        :ok
    end
  end

  defp schedule_collect(:midnight) do
    now = Timex.now()
    next_midnight = now |> Timex.shift(days: 1) |> Timex.beginning_of_day()
    time_till_midnight = max(Timex.diff(next_midnight, now, :milliseconds), 0)
    Process.send_after(self(), :collect, time_till_midnight)
  end

  defp schedule_collect(interval_seconds) when is_integer(interval_seconds) do
    Process.send_after(self(), :collect, interval_seconds * 1000)
  end

  defp key_hash(key) do
    key
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> binary_part(0, 16)
    |> Base.encode32(case: :lower, padding: false)
  end

  defp sharded_path(<<a::binary-size(2), b::binary-size(2), rest::binary>>) do
    Path.join([a, b, rest])
  end

  defp full_path(base_path, path), do: Path.join(base_path, path)

  defp generate_async(base_path, path, generator) do
    task =
      Task.Supervisor.async_nolink(
        Asciinema.TaskSupervisor,
        __MODULE__,
        :generate,
        [base_path, path, generator]
      )

    task.ref
  end

  defp collect_async(server, base_path, buckets) do
    {:ok, _} =
      Task.Supervisor.start_child(
        Asciinema.TaskSupervisor,
        __MODULE__,
        :collect_and_cast,
        [server, base_path, buckets]
      )

    :ok
  end

  defp normalize_collect_interval(:midnight), do: :midnight

  defp normalize_collect_interval(interval_seconds)
       when is_integer(interval_seconds) and interval_seconds > 0 do
    interval_seconds
  end

  defp init_buckets(buckets) do
    for {bucket, ttl} <- buckets, into: %{} do
      {bucket, %{ttl: ttl, inflight: %{}}}
    end
  end

  defp collect_candidates_with_fd(bucket_path, cutoff) do
    case System.find_executable("fd") do
      nil ->
        []

      fd ->
        args = [
          "--type",
          "f",
          "--absolute-path",
          "--changed-before",
          "@#{cutoff}",
          ".",
          bucket_path
        ]

        case System.cmd(fd, args, stderr_to_stdout: true) do
          {output, 0} ->
            output
            |> String.split("\n", trim: true)
            |> Enum.map(&{&1, cutoff})

          {output, _} ->
            Logger.error("file cache collect failed: #{output}")
            []
        end
    end
  end

  defp reply_waiters(state, bucket, path, reply) do
    waiters = get_in(state, [:buckets, bucket, :inflight, path])
    Enum.each(waiters, &GenServer.reply(&1, reply))
    update_in(state, [:buckets, bucket, :inflight], &Map.delete(&1, path))
  end

  defp to_error(bucket, key, {:generator_failed, kind, reason, stacktrace}) do
    %Error{
      type: :generator_failed,
      bucket: bucket,
      key: key,
      kind: kind,
      reason: reason,
      stacktrace: stacktrace
    }
  end

  defp to_error(bucket, key, {:task_crash, reason}) do
    %Error{
      type: :task_crash,
      bucket: bucket,
      key: key,
      reason: reason
    }
  end

  defp to_error(bucket, key, {:timeout, timeout}) do
    %Error{
      type: :timeout,
      bucket: bucket,
      key: key,
      reason: timeout
    }
  end
end
