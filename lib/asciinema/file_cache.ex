defmodule Asciinema.FileCache do
  use GenServer
  require Logger

  @default_get_path_timeout 5_000
  @default_cache_cleanup_interval :midnight
  @default_work_dir_cleanup_interval 60 * 60
  @default_work_dir_ttl 60 * 60
  @work_ns "tmp"

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
    base_path = opts |> Keyword.fetch!(:path) |> Path.expand()
    buckets = Keyword.get(opts, :buckets, [])

    cache_cleanup_interval =
      Keyword.get(opts, :cache_cleanup_interval, @default_cache_cleanup_interval)

    work_dir_cleanup_interval =
      Keyword.get(opts, :work_dir_cleanup_interval, @default_work_dir_cleanup_interval)

    work_dir_ttl = Keyword.get(opts, :work_dir_ttl, @default_work_dir_ttl)

    init_arg = %{
      base_path: base_path,
      buckets: buckets,
      cache_cleanup_interval: cache_cleanup_interval,
      work_dir_cleanup_interval: work_dir_cleanup_interval,
      work_dir_ttl: work_dir_ttl
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
        cache_cleanup_interval: cache_cleanup_interval,
        work_dir_cleanup_interval: work_dir_cleanup_interval,
        work_dir_ttl: work_dir_ttl
      }) do
    schedule_cache_cleanup(cache_cleanup_interval)
    schedule_work_dir_cleanup(work_dir_cleanup_interval)

    if !System.find_executable("fd") do
      Logger.warning("fd executable not found in PATH, required for file cache cleanup")
    end

    state = %{
      base_path: base_path,
      buckets: init_buckets(buckets),
      task_refs: %{},
      cache_cleanup_interval: cache_cleanup_interval,
      work_dir_cleanup_interval: work_dir_cleanup_interval,
      work_dir_ttl: work_dir_ttl
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
  def handle_cast({:prune_stale_files, stale_files}, state) do
    prune_stale_files(stale_files)

    {:noreply, state}
  end

  @impl true
  def handle_info(:cleanup_cache, state) do
    bucket_ttls = Enum.map(state.buckets, fn {bucket, %{ttl: ttl}} -> {bucket, ttl} end)
    :ok = collect_and_report_stale_files_async(self(), state.base_path, bucket_ttls)
    schedule_cache_cleanup(state.cache_cleanup_interval)

    {:noreply, state}
  end

  @impl true
  def handle_info(:cleanup_work_dirs, state) do
    :ok = cleanup_work_dirs_async(state.base_path, state.work_dir_ttl)
    schedule_work_dir_cleanup(state.work_dir_cleanup_interval)

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
    work_root = full_path(base_path, @work_ns)
    work_dir = create_work_dir!(work_root)

    try do
      :ok = File.mkdir_p(Path.dirname(full_path))
      output_path = generator.(work_dir)

      case validate_output_path(work_dir, output_path) do
        {:ok, output_path} ->
          :ok = File.rename(output_path, full_path)
          _ = File.rm_rf(work_dir)
          {:ok, full_path}

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      exception ->
        {:error, {:generator_failed, :error, exception, __STACKTRACE__}}
    catch
      kind, reason ->
        {:error, {:generator_failed, kind, reason, __STACKTRACE__}}
    end
  end

  def collect_stale_files(base_path, buckets) do
    buckets
    |> Enum.map(&collect_stale_bucket_files(base_path, &1))
    |> Enum.flat_map(& &1)
  end

  @doc false
  def collect_and_report_stale_files(server, base_path, buckets) do
    stale_files = collect_stale_files(base_path, buckets)
    GenServer.cast(server, {:prune_stale_files, stale_files})
  end

  defp collect_stale_bucket_files(base_path, {bucket, ttl_seconds}) do
    bucket_path = full_path(base_path, to_string(bucket))
    cutoff = System.os_time(:second) - ttl_seconds

    if File.dir?(bucket_path) do
      collect_stale_files_with_fd(bucket_path, cutoff)
    else
      []
    end
  end

  def prune_stale_files(stale_files) do
    Enum.each(stale_files, &prune_stale_file/1)
  end

  def cleanup_work_dirs(base_path, ttl_seconds) do
    work_root = full_path(base_path, @work_ns)
    cutoff = System.os_time(:second) - ttl_seconds
    :ok = File.mkdir_p(work_root)
    {:ok, entries} = File.ls(work_root)

    Enum.each(entries, fn entry ->
      cleanup_work_dir(Path.join(work_root, entry), cutoff)
    end)
  end

  defp prune_stale_file({full_path, cutoff}) do
    case File.stat(full_path, time: :posix) do
      {:ok, %File.Stat{mtime: mtime}} when mtime < cutoff ->
        _ = File.rm(full_path)
        :ok

      _ ->
        :ok
    end
  end

  defp cleanup_work_dir(path, cutoff) do
    case File.stat(path, time: :posix) do
      {:ok, %File.Stat{mtime: mtime}} when mtime < cutoff ->
        _ = File.rm_rf(path)
        :ok

      _ ->
        :ok
    end
  end

  defp schedule_cache_cleanup(:midnight) do
    now = Timex.now()
    next_midnight = now |> Timex.shift(days: 1) |> Timex.beginning_of_day()
    time_till_midnight = max(Timex.diff(next_midnight, now, :milliseconds), 0)
    Process.send_after(self(), :cleanup_cache, time_till_midnight)
  end

  defp schedule_cache_cleanup(interval_seconds) when is_integer(interval_seconds) do
    Process.send_after(self(), :cleanup_cache, interval_seconds * 1000)
  end

  defp schedule_work_dir_cleanup(interval_seconds) when is_integer(interval_seconds) do
    Process.send_after(self(), :cleanup_work_dirs, interval_seconds * 1000)
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

  defp collect_and_report_stale_files_async(server, base_path, buckets) do
    {:ok, _} =
      Task.Supervisor.start_child(
        Asciinema.TaskSupervisor,
        __MODULE__,
        :collect_and_report_stale_files,
        [server, base_path, buckets]
      )

    :ok
  end

  defp cleanup_work_dirs_async(base_path, ttl_seconds) do
    {:ok, _} =
      Task.Supervisor.start_child(
        Asciinema.TaskSupervisor,
        __MODULE__,
        :cleanup_work_dirs,
        [base_path, ttl_seconds]
      )

    :ok
  end

  defp init_buckets(buckets) do
    for {bucket, ttl} <- buckets, into: %{} do
      {bucket, %{ttl: ttl, inflight: %{}}}
    end
  end

  defp collect_stale_files_with_fd(bucket_path, cutoff) do
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
            Logger.error("file cache stale file collection failed: #{output}")
            []
        end
    end
  end

  defp reply_waiters(state, bucket, path, reply) do
    waiters = get_in(state, [:buckets, bucket, :inflight, path])
    Enum.each(waiters, &GenServer.reply(&1, reply))
    update_in(state, [:buckets, bucket, :inflight], &Map.delete(&1, path))
  end

  defp create_work_dir!(work_root) do
    :ok = File.mkdir_p(work_root)
    path = Path.join(work_root, UUID.uuid4())
    :ok = File.mkdir(path)

    path
  end

  defp validate_output_path(work_dir, output_path) when is_binary(output_path) do
    abs_output_path = Path.absname(output_path, work_dir)

    if !path_within_dir?(abs_output_path, work_dir) do
      {:error, {:invalid_generator_output, {:outside_work_dir, output_path}}}
    else
      case File.stat(abs_output_path) do
        {:ok, %File.Stat{type: :regular}} ->
          {:ok, abs_output_path}

        {:ok, %File.Stat{type: type}} ->
          {:error, {:invalid_generator_output, {:not_regular_file, type}}}

        {:error, reason} ->
          {:error, {:invalid_generator_output, {:missing_or_unreadable, output_path, reason}}}
      end
    end
  end

  defp validate_output_path(_work_dir, output_path) do
    {:error, {:invalid_generator_output, {:invalid_return, output_path}}}
  end

  defp path_within_dir?(path, dir) do
    path == dir or String.starts_with?(path, dir <> "/")
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

  defp to_error(bucket, key, {:invalid_generator_output, reason}) do
    %Error{
      type: :invalid_generator_output,
      bucket: bucket,
      key: key,
      reason: reason
    }
  end
end
