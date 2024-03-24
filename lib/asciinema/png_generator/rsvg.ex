defmodule Asciinema.PngGenerator.Rsvg do
  @behaviour Asciinema.PngGenerator
  use GenServer

  @pool_name :worker
  @acquire_timeout 5_000
  @result_timeout 15_000
  @zoom 2

  def generate(asciicast) do
    {:ok, tmp_dir_path} = Briefly.create(directory: true)

    try do
      :poolboy.transaction(
        @pool_name,
        fn pid ->
          try do
            GenServer.call(pid, {:generate, asciicast, tmp_dir_path}, @result_timeout)
          catch
            :exit, {:timeout, _} ->
              {:error, :timeout}
          end
        end,
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
    [
      {:name, {:local, @pool_name}},
      {:worker_module, __MODULE__},
      {:size, pool_size()},
      {:max_overflow, 0}
    ]
  end

  defp do_generate(asciicast, tmp_dir_path) do
    svg_path = Path.join(tmp_dir_path, "tmp.svg")
    png_path = Path.join(tmp_dir_path, "tmp.png")

    svg =
      AsciinemaWeb.RecordingSVG.show(%{
        asciicast: asciicast,
        font_family: font_family(),
        rx: 0,
        ry: 0
      })

    File.write!(svg_path, Phoenix.HTML.Safe.to_iodata(svg))

    args = [svg_path, png_path, "#{@zoom}"]
    opts = [stderr_to_stdout: true]

    case System.cmd(script_path(), args, opts) do
      {_, 0} ->
        {:ok, png_path}

      {_, 124} ->
        {:error, :busy}

      result ->
        {:error, result}
    end
  end

  defp script_path do
    Path.join(:code.priv_dir(:asciinema), "svg2png.sh")
  end

  defp pool_size do
    Keyword.get(Application.get_env(:asciinema, __MODULE__), :pool_size)
  end

  defp font_family do
    Keyword.get(Application.get_env(:asciinema, __MODULE__), :font_family)
  end
end
