defmodule AsciinemaWeb.MediumHTMLTest do
  use ExUnit.Case, async: true

  alias Asciinema.{Colors, Themes}
  alias AsciinemaWeb.MediumHTML

  doctest AsciinemaWeb.MediumHTML, import: true

  describe "card_colors/1" do
    test "produces accessible metadata colors for all built-in terminal themes" do
      for name <- Themes.terminal_themes() do
        theme = Themes.named_theme(name)
        colors = MediumHTML.card_colors(theme)

        assert Colors.contrast_ratio(colors.foreground, theme.bg) >= 4.5
        assert Colors.contrast_ratio(colors.muted, theme.bg) >= 4.5
        assert Colors.contrast_ratio(colors.badge_foreground, colors.badge_background) >= 4.5
      end
    end

    test "corrects low-contrast custom terminal colors" do
      theme =
        Themes.custom_theme("#777777", "#888888", String.duplicate("#808080:", 15) <> "#808080")

      colors = MediumHTML.card_colors(theme)

      assert Colors.contrast_ratio(colors.foreground, theme.bg) >= 4.5
      assert Colors.contrast_ratio(colors.muted, theme.bg) >= 4.5
      assert Colors.contrast_ratio(colors.badge_foreground, colors.badge_background) >= 4.5
    end
  end
end
