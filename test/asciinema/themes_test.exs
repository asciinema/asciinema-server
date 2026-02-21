defmodule Asciinema.ThemesTest do
  use ExUnit.Case, async: true

  alias Asciinema.Themes

  describe "with_256_palette/2" do
    test "generates fixed 256-color palette by default" do
      theme = Themes.named_theme("dracula") |> Themes.with_256_palette(false)

      assert_theme_samples(theme, [
        {16, "#000000"},
        {21, "#0000ff"},
        {46, "#00ff00"},
        {51, "#00ffff"},
        {196, "#ff0000"},
        {201, "#ff00ff"},
        {226, "#ffff00"},
        {231, "#ffffff"},
        {102, "#878787"},
        {145, "#afafaf"},
        {232, "#080808"},
        {243, "#767676"},
        {255, "#eeeeee"}
      ])
    end

    test "generates adaptive 256-color palette when enabled" do
      theme = Themes.named_theme("dracula") |> Themes.with_256_palette(true)

      assert_theme_samples(theme, [
        {16, "#282a36"},
        {21, "#bd93f9"},
        {46, "#50fa7b"},
        {51, "#8be9fd"},
        {196, "#ff5555"},
        {201, "#ff79c6"},
        {226, "#f1fa8c"},
        {231, "#f8f8f2"},
        {102, "#ab9c99"},
        {145, "#d1c1bc"},
        {232, "#2f313d"},
        {243, "#84868b"},
        {255, "#efefea"}
      ])
    end
  end

  defp assert_theme_samples(theme, samples) do
    Enum.each(samples, fn {idx, expected_color} ->
      assert Themes.color(theme, idx) == expected_color
    end)
  end
end
