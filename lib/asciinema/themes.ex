defmodule Asciinema.Themes do
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

  def color(theme, n) do
    cond do
      n < 16 ->
        elem(theme.palette, n)

      n < 232 ->
        n = n - 16
        r = hex(shift(div(n, 36) * 40))
        n = rem(n, 36)
        g = hex(shift(div(n, 6) * 40))
        b = hex(shift(rem(n, 6) * 40))

        "##{r}#{g}#{b}"

      n < 256 ->
        c = hex(8 + (n - 232) * 10)

        "##{c}#{c}#{c}"

      true ->
        theme.fg
    end
  end

  defp shift(0), do: 0
  defp shift(n), do: 55 + n

  defp hex(int) do
    int
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end
end
