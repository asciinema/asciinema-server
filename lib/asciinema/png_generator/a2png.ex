defmodule Asciinema.PngGenerator.A2png do
  @behaviour Asciinema.PngGenerator
  use GenServer
  alias Asciinema.Asciicast

  @result_timeout 30000
  @acquire_timeout 5000

  def generate(%Asciicast{} = asciicast) do
    {:ok, tmp_dir_path} = Briefly.create(directory: true)

    :poolboy.transaction(
      :worker,
      &GenServer.call(&1, {:gen_png, asciicast, tmp_dir_path}, @result_timeout), @acquire_timeout
    )
  end

  # GenServer API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:gen_png, asciicast, tmp_dir_path}, _from, state) do
    {:reply, do_gen(asciicast, tmp_dir_path), state}
  end

  defp do_gen(asciicast, tmp_dir_path) do
    path = Asciicast.json_store_path(asciicast)
    json_path = Path.join(tmp_dir_path, "tmp.json")
    png_path = Path.join(tmp_dir_path, "tmp.png")
    snapshot_at = "#{asciicast.duration / 2}"

    with {:ok, file} <- file_store().open(path),
         {:ok, _} <- :file.copy(file, json_path),
         %{status: 0} <- Porcelain.exec(bin_path(), [json_path, png_path, snapshot_at]) do
      {:ok, png_path}
    else
      otherwise ->
        otherwise
    end
  end

  def bin_path do
    Keyword.get(Application.get_env(:asciinema, __MODULE__), :bin_path)
  end

  defp file_store do
    Application.get_env(:asciinema, :file_store)
  end
end
