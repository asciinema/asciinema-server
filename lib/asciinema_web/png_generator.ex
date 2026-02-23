defmodule AsciinemaWeb.PngGenerator do
  use GenServer

  alias AsciinemaWeb.RecordingSVG

  @name __MODULE__
  @zoom 2
  @call_timeout 30_000

  # Bump when PNG output bytes can change without SVG cache key changing
  @png_renderer_salt 1

  defmodule Error do
    defexception [:type, :reason, retryable: false]

    @impl true
    def message(%__MODULE__{type: type, reason: reason, retryable: retryable}) do
      suffix = if retryable, do: " (retryable)", else: ""
      "png generation #{type}: #{inspect(reason)}#{suffix}"
    end
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, Keyword.put_new(opts, :name, @name))
  end

  @impl true
  def init(_) do
    {:ok, nil}
  end

  def generate(asciicast, png_path) do
    generate(@name, asciicast, png_path)
  end

  def generate(server, asciicast, png_path) do
    try do
      case GenServer.call(server, {:generate, asciicast, png_path}, @call_timeout) do
        :ok ->
          :ok

        {:error, error} ->
          raise error
      end
    catch
      :exit, {:timeout, {GenServer, :call, _}} ->
        raise Error, type: :busy, reason: @call_timeout, retryable: true
    end
  end

  def png_cache_key(asciicast) do
    key = [
      RecordingSVG.svg_cache_key(asciicast),
      <<0>>,
      to_string(font_family() || ""),
      <<0>>,
      Integer.to_string(@png_renderer_salt)
    ]

    :crypto.hash(:sha256, key)
    |> binary_part(0, 12)
    |> Base.url_encode64(padding: false)
  end

  @impl true
  def handle_call({:generate, asciicast, png_path}, _from, state) do
    reply =
      try do
        case do_generate(asciicast, png_path) do
          :ok ->
            :ok

          {:error, %Error{} = error} ->
            {:error, error}
        end
      rescue
        exception ->
          {:error, %Error{type: :generator_failed, reason: {:error, exception}}}
      catch
        kind, reason ->
          {:error, %Error{type: :generator_failed, reason: {kind, reason}}}
      end

    {:reply, reply, state}
  end

  defp do_generate(asciicast, png_path) do
    svg_path = png_path <> ".svg"

    try do
      svg =
        RecordingSVG.full(%{
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
          :ok

        {_, 124} ->
          {:error, %Error{type: :timeout, reason: :rsvg_convert, retryable: true}}

        result ->
          {:error, %Error{type: :generator_failed, reason: result}}
      end
    after
      _ = File.rm(svg_path)
    end
  end

  defp script_path do
    Path.join(:code.priv_dir(:asciinema), "svg2png.sh")
  end

  defp font_family do
    Keyword.get(Application.get_env(:asciinema, __MODULE__), :font_family)
  end
end
