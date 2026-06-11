defmodule Asciinema.MediaTest do
  use ExUnit.Case, async: true

  alias Asciinema.Media

  describe "theme/1" do
    test "uses the captured palette when configured as original" do
      theme = Media.theme(stream(term_theme_name: "original"))

      assert theme.name == "Custom"
      assert theme.fg == "#aabbcc"
    end

    test "falls back to the default named theme when configured as original without a palette" do
      # A later session starting without a theme resets the captured fields.
      stream =
        stream(
          term_theme_name: "original",
          term_theme_fg: nil,
          term_theme_bg: nil,
          term_theme_palette: nil
        )

      assert Media.theme(stream).name == "asciinema"
    end

    test "prefers the captured palette over a named theme when so configured" do
      theme = Media.theme(stream(term_theme_name: "dracula", term_theme_prefer_original: true))

      assert theme.name == "Custom"
    end

    test "uses the named theme when prefer-original is set but nothing was captured" do
      stream =
        stream(
          term_theme_name: "dracula",
          term_theme_prefer_original: true,
          term_theme_fg: nil,
          term_theme_bg: nil,
          term_theme_palette: nil
        )

      assert Media.theme(stream).name == "Dracula"
    end
  end

  defp stream(attrs) do
    struct!(
      %Asciinema.Streaming.Stream{
        term_theme_prefer_original: false,
        term_theme_fg: "#aabbcc",
        term_theme_bg: "#112233",
        term_theme_palette: Enum.map_join(0..15, ":", fn i -> "#0000#{16 + i}" end),
        user: %Asciinema.Accounts.User{}
      },
      attrs
    )
  end
end
