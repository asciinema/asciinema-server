defmodule Asciinema.PngGenerator.A2png do
  @behaviour Asciinema.PngGenerator
  use GenServer
  alias Asciinema.Asciicasts.Asciicast
  alias Asciinema.PngGenerator.PngParams

  @pool_name :worker
  @acquire_timeout 5000
  @a2png_timeout_sec 30
  @result_timeout (@a2png_timeout_sec * 2) * 1_000

  def generate(%Asciicast{} = asciicast, %PngParams{} = png_params) do
    {:ok, tmp_dir_path} = Briefly.create(directory: true)

    try do
      :poolboy.transaction(
        @pool_name,
        (fn pid ->
          try do
            GenServer.call(pid, {:generate, asciicast, png_params, tmp_dir_path}, @result_timeout)
          catch
            :exit, {:timeout, _} ->
              {:error, :timeout}
          end
        end),
        @acquire_timeout
      )
    catch
      :exit, {:timeout, _} ->
        {:error, :busy}
    end
  end

  # GenServer API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:generate, asciicast, png_params, tmp_dir_path}, _from, state) do
    {:reply, do_generate(asciicast, png_params, tmp_dir_path), state}
  end

  def poolboy_config do
    [{:name, {:local, @pool_name}},
     {:worker_module, __MODULE__},
     {:size, pool_size()},
     {:max_overflow, 0}]
  end

  defp do_generate(asciicast, png_params, tmp_dir_path) do
    path = Asciicast.json_store_path(asciicast)
    json_path = Path.join(tmp_dir_path, "tmp.json")
    png_path = Path.join(tmp_dir_path, "tmp.png")

    args = [
      json_path,
      png_path,
      Float.to_string(png_params.snapshot_at),
      png_params.theme,
      Integer.to_string(png_params.scale)
    ]

    :ok = file_store().download_file(path, json_path)

    path = Path.expand(bin_path())
    env = [{"A2PNG_TIMEOUT", "#{@a2png_timeout_sec}"}]
    opts = [env: env, stderr_to_stdout: true]

    case System.cmd(path, args, opts) do
      {_, 0} ->
        {:ok, png_path}

      {_, 124} ->
        {:error, :busy}

      result ->
        {:error, result}
    end
  end

  defp bin_path do
    Keyword.get(Application.get_env(:asciinema, __MODULE__), :bin_path)
  end

  defp pool_size do
    Keyword.get(Application.get_env(:asciinema, __MODULE__), :pool_size)
  end

  defp file_store do
    Application.get_env(:asciinema, :file_store)
  end
end
