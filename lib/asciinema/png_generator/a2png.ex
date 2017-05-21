defmodule Asciinema.PngGenerator.A2png do
  @behaviour Asciinema.PngGenerator
  use GenServer
  alias Asciinema.Asciicast

  @pool_name :worker
  @acquire_timeout 5000
  @a2png_timeout 30000
  @result_timeout 35000

  def generate(%Asciicast{} = asciicast) do
    {:ok, tmp_dir_path} = Briefly.create(directory: true)

    try do
      :poolboy.transaction(
        @pool_name,
        (fn pid ->
          try do
            GenServer.call(pid, {:generate, asciicast, tmp_dir_path}, @result_timeout)
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

  def handle_call({:generate, asciicast, tmp_dir_path}, _from, state) do
    {:reply, do_generate(asciicast, tmp_dir_path), state}
  end

  def poolboy_config do
    [{:name, {:local, @pool_name}},
     {:worker_module, __MODULE__},
     {:size, pool_size()},
     {:max_overflow, 0}]
  end

  defp do_generate(asciicast, tmp_dir_path) do
    path = Asciicast.json_store_path(asciicast)
    json_path = Path.join(tmp_dir_path, "tmp.json")
    png_path = Path.join(tmp_dir_path, "tmp.png")
    snapshot_at = "#{asciicast.duration / 2}"

    with {:ok, file} <- file_store().open(path),
         {:ok, _} <- :file.copy(file, json_path),
         process <- Porcelain.spawn(bin_path(), [json_path, png_path, snapshot_at]),
         {:ok, %{status: 0}} <- Porcelain.Process.await(process, @a2png_timeout) do
      {:ok, png_path}
    else
      otherwise ->
        otherwise
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
