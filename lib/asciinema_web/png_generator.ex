defmodule AsciinemaWeb.PngGenerator do
  use GenServer

  alias AsciinemaWeb.RecordingSVG

  @name __MODULE__
  @zoom 2
  @call_timeout 30_000
  @symbols_font_name "Symbols Nerd Font"

  # Bump when PNG output bytes can change without SVG cache key changing
  @png_renderer_salt 2

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

  def generate(asciicast, tmp_dir_path) do
    generate(@name, asciicast, tmp_dir_path)
  end

  def generate(server, asciicast, tmp_dir_path) do
    try do
      case GenServer.call(server, {:generate, asciicast, tmp_dir_path}, @call_timeout) do
        {:ok, png_path} ->
          png_path

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
  def handle_call({:generate, asciicast, tmp_dir_path}, _from, state) do
    reply =
      try do
        do_generate(asciicast, tmp_dir_path)
      rescue
        exception ->
          {:error, %Error{type: :failure, reason: {:error, exception}}}
      catch
        kind, reason ->
          {:error, %Error{type: :failure, reason: {kind, reason}}}
      end

    {:reply, reply, state}
  end

  defp do_generate(asciicast, tmp_dir_path) do
    png_path = Path.join(tmp_dir_path, "#{asciicast.id}.png")
    svg_path = Path.join(tmp_dir_path, "#{asciicast.id}.svg")
    fontconfig_path = Path.join(tmp_dir_path, "fonts.conf")

    svg =
      RecordingSVG.full(%{
        asciicast: asciicast,
        font_family: font_family(),
        rx: 0,
        ry: 0
      })

    File.write!(svg_path, Phoenix.HTML.Safe.to_iodata(svg))
    File.write!(fontconfig_path, fontconfig_xml())

    args = [svg_path, png_path, "#{@zoom}"]
    opts = [stderr_to_stdout: true, env: [{"FONTCONFIG_FILE", fontconfig_path}]]

    case System.cmd(script_path(), args, opts) do
      {_, 0} ->
        {:ok, png_path}

      {_, 124} ->
        {:error, %Error{type: :timeout, reason: :rsvg_convert, retryable: true}}

      result ->
        {:error, %Error{type: :failure, reason: result}}
    end
  end

  defp script_path do
    Path.join(:code.priv_dir(:asciinema), "svg2png.sh")
  end

  defp fontconfig_xml do
    """
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <include ignore_missing="yes">fonts.conf</include>
      <dir>#{fonts_dir()}</dir>
      <selectfont>
        <rejectfont>
          <glob>#{Path.join(fonts_dir(), "*.woff2")}</glob>
        </rejectfont>
      </selectfont>
    </fontconfig>
    """
  end

  defp fonts_dir do
    Application.app_dir(:asciinema, "priv/static/fonts")
  end

  defp font_family do
    Application.get_env(:asciinema, __MODULE__, [])
    |> Keyword.fetch!(:font_family)
    |> ensure_symbols_font_family()
  end

  defp ensure_symbols_font_family(font_family) do
    if String.contains?(font_family, @symbols_font_name) do
      font_family
    else
      font_family <> ",'#{@symbols_font_name}'"
    end
  end
end
