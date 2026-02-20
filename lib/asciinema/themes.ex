defmodule Asciinema.Themes do
  alias Asciinema.Colors

  defmodule Theme do
    defstruct [:name, :fg, :bg, :palette]
  end

  @themes %{
    "asciinema" => %{
      name: "asciinema",
      fg: "#cccccc",
      bg: "#121314",
      palette: {
        "#000000",
        "#dd3c69",
        "#4ebf22",
        "#ddaf3c",
        "#26b0d7",
        "#b954e1",
        "#54e1b9",
        "#d9d9d9",
        "#4d4d4d",
        "#dd3c69",
        "#4ebf22",
        "#ddaf3c",
        "#26b0d7",
        "#b954e1",
        "#54e1b9",
        "#ffffff"
      }
    },
    "dracula" => %{
      name: "Dracula",
      fg: "#f8f8f2",
      bg: "#282a36",
      palette: {
        "#21222c",
        "#ff5555",
        "#50fa7b",
        "#f1fa8c",
        "#bd93f9",
        "#ff79c6",
        "#8be9fd",
        "#f8f8f2",
        "#6272a4",
        "#ff6e6e",
        "#69ff94",
        "#ffffa5",
        "#d6acff",
        "#ff92df",
        "#a4ffff",
        "#ffffff"
      }
    },
    "monokai" => %{
      name: "Monokai",
      fg: "#f8f8f2",
      bg: "#272822",
      palette: {
        "#272822",
        "#f92672",
        "#a6e22e",
        "#f4bf75",
        "#66d9ef",
        "#ae81ff",
        "#a1efe4",
        "#f8f8f2",
        "#75715e",
        "#f92672",
        "#a6e22e",
        "#f4bf75",
        "#66d9ef",
        "#ae81ff",
        "#a1efe4",
        "#f9f8f5"
      }
    },
    "nord" => %{
      name: "Nord",
      fg: "#eceff4",
      bg: "#2e3440",
      palette: {
        "#3b4252",
        "#bf616a",
        "#a3be8c",
        "#ebcb8b",
        "#81a1c1",
        "#b48ead",
        "#88c0d0",
        "#eceff4",
        "#3b4252",
        "#bf616a",
        "#a3be8c",
        "#ebcb8b",
        "#81a1c1",
        "#b48ead",
        "#88c0d0",
        "#eceff4"
      }
    },
    "solarized-dark" => %{
      name: "Solarized Dark",
      fg: "#839496",
      bg: "#002b36",
      palette: {
        "#073642",
        "#dc322f",
        "#859900",
        "#b58900",
        "#268bd2",
        "#d33682",
        "#2aa198",
        "#eee8d5",
        "#002b36",
        "#cb4b16",
        "#586e75",
        "#657b83",
        "#839496",
        "#6c71c4",
        "#93a1a1",
        "#fdf6e3"
      }
    },
    "solarized-light" => %{
      name: "Solarized Light",
      fg: "#657b83",
      bg: "#fdf6e3",
      palette: {
        "#073642",
        "#dc322f",
        "#859900",
        "#b58900",
        "#268bd2",
        "#d33682",
        "#2aa198",
        "#eee8d5",
        "#002b36",
        "#cb4b16",
        "#586e75",
        "#657c83",
        "#839496",
        "#6c71c4",
        "#93a1a1",
        "#fdf6e3"
      }
    },
    "tango" => %{
      name: "Tango",
      fg: "#cccccc",
      bg: "#121314",
      palette: {
        "#000000",
        "#cc0000",
        "#4e9a06",
        "#c4a000",
        "#3465a4",
        "#75507b",
        "#06989a",
        "#d3d7cf",
        "#555753",
        "#ef2929",
        "#8ae234",
        "#fce94f",
        "#729fcf",
        "#ad7fa8",
        "#34e2e2",
        "#eeeeec"
      }
    },
    "gruvbox-dark" => %{
      name: "Gruvbox Dark",
      fg: "#fbf1c7",
      bg: "#282828",
      palette: {
        "#282828",
        "#cc241d",
        "#98971a",
        "#d79921",
        "#458588",
        "#b16286",
        "#689d6a",
        "#a89984",
        "#7c6f64",
        "#fb4934",
        "#b8bb26",
        "#fabd2f",
        "#83a598",
        "#d3869b",
        "#8ec07c",
        "#fbf1c7"
      }
    }
  }

  def terminal_themes, do: Map.keys(@themes)

  def display_name("original"), do: "Original terminal theme"
  def display_name(theme), do: Map.fetch!(@themes, theme).name

  def named_theme(name) when is_binary(name), do: struct(Theme, Map.fetch!(@themes, name))

  def custom_theme(fg, bg, palette) do
    %Theme{
      name: "Custom",
      fg: fg,
      bg: bg,
      palette: List.to_tuple(String.split(palette, ":"))
    }
  end

  def with_256_palette(theme, adaptive_palette \\ false) do
    palette = palette(theme, adaptive_palette)
    %{theme | palette: List.to_tuple(palette)}
  end

  def palette(theme, adaptive_palette \\ false) do
    base16 = normalize_base_palette(theme.palette)

    if adaptive_palette do
      generate_adaptive_256_palette(base16, theme.bg, theme.fg)
    else
      generate_fixed_256_palette(base16)
    end
  end

  def color(theme, n) when is_integer(n) and n >= 0 do
    cond do
      n < palette_size(theme.palette) ->
        palette_color(theme.palette, n)

      n < 256 ->
        fixed_palette_color(n)

      true ->
        theme.fg
    end
  end

  def color(theme, _n), do: theme.fg

  defp palette_size(palette) when is_tuple(palette), do: tuple_size(palette)
  defp palette_size(palette) when is_list(palette), do: length(palette)

  defp palette_color(palette, n) when is_tuple(palette), do: elem(palette, n)
  defp palette_color(palette, n) when is_list(palette), do: Enum.at(palette, n)

  defp fixed_palette_color(n) when n >= 16 and n < 232 do
    n = n - 16
    r = shift(div(n, 36))
    n = rem(n, 36)
    g = shift(div(n, 6))
    b = shift(rem(n, 6))

    Colors.rgb_to_hex(r, g, b)
  end

  defp fixed_palette_color(n) when n >= 232 and n < 256 do
    c = 8 + (n - 232) * 10
    Colors.rgb_to_hex(c, c, c)
  end

  defp shift(0), do: 0
  defp shift(n), do: 55 + n * 40

  defp normalize_base_palette(palette) do
    palette =
      palette
      |> palette_to_list()
      |> Enum.take(16)

    case length(palette) do
      16 ->
        palette

      n when n >= 8 ->
        palette ++ Enum.map(n..15, &Enum.at(palette, &1 - 8))

      n ->
        palette ++ List.duplicate("#000000", 16 - n)
    end
  end

  defp generate_fixed_256_palette(base16) do
    base16 ++ Enum.map(16..255, &fixed_palette_color/1)
  end

  defp generate_adaptive_256_palette(base16, bg, fg) do
    bg_lab = Colors.hex_to_oklab(bg)
    fg_lab = Colors.hex_to_oklab(fg)
    [_c000, c100, c010, c110, c001, c101, c011 | _rest] = Enum.map(base16, &Colors.hex_to_oklab/1)

    cube =
      Enum.flat_map(0..5, fn r ->
        t_r = r / 5
        c0 = Colors.lerp_oklab(t_r, bg_lab, c100)
        c1 = Colors.lerp_oklab(t_r, c010, c110)
        c2 = Colors.lerp_oklab(t_r, c001, c101)
        c3 = Colors.lerp_oklab(t_r, c011, fg_lab)

        Enum.flat_map(0..5, fn g ->
          t_g = g / 5
          c4 = Colors.lerp_oklab(t_g, c0, c1)
          c5 = Colors.lerp_oklab(t_g, c2, c3)

          Enum.map(0..5, fn b ->
            t_b = b / 5
            c6 = Colors.lerp_oklab(t_b, c4, c5)
            Colors.oklab_to_hex(c6)
          end)
        end)
      end)

    grayscale =
      Enum.map(0..23, fn i ->
        t = (i + 1) / 25
        Colors.lerp_oklab(t, bg_lab, fg_lab) |> Colors.oklab_to_hex()
      end)

    base16 ++ cube ++ grayscale
  end

  defp palette_to_list(palette) when is_tuple(palette), do: Tuple.to_list(palette)
  defp palette_to_list(palette) when is_list(palette), do: palette
end
