defmodule AsciinemaWeb.RecordingSvgTest do
  use ExUnit.Case, async: true
  import Asciinema.Factory
  import Asciinema.PngUtil
  alias Asciinema.Recordings.Snapshot
  alias AsciinemaWeb.RecordingSVG

  test "cursor coordinates contribute to SVG cache identity" do
    rows = [[{"  ", %{}, 1}]]

    keys =
      for cursor <- [nil, {0, 0}, {1, 0}] do
        build(:asciicast, snapshot: Snapshot.from_segments(rows, cursor))
        |> RecordingSVG.svg_cache_key()
      end

    assert length(Enum.uniq(keys)) == 3
  end

  test "full export uses dimension overrides, font settings, and centered branding" do
    recording =
      build(:asciicast,
        term_cols_override: 3,
        term_rows_override: 1,
        snapshot: Snapshot.from_segments([[{"abc", %{}, 1}]])
      )

    svg =
      RecordingSVG.full(%{asciicast: recording, font_family: "monospace", rx: 0, ry: 0})
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    png = embedded_png(svg)
    assert {png.width, png.height} == {40, 48}
    assert svg =~ "<?xml"
    assert svg =~ ~s(font-family="monospace")
    assert svg =~ ~s(rx="0")
    assert svg =~ ~s(ry="0")

    [logo_attrs] =
      svg
      |> LazyHTML.from_document()
      |> LazyHTML.query("svg[x][y]:has(#small-triangle-mask)")
      |> LazyHTML.attributes()

    assert %{"x" => "17.325", "y" => "14.933", "width" => "7.467", "height" => "7.467"} =
             Map.new(logo_attrs)

    assert svg =~ "abc"
  end

  test "thumbnail export is standalone and unbranded" do
    recording = build(:asciicast, snapshot: Snapshot.from_segments([]))

    svg =
      RecordingSVG.render_to_iodata(:thumbnail, recording)
      |> IO.iodata_to_binary()

    assert svg =~ "<?xml"
    refute svg =~ "small-triangle-mask"
  end

  test "exports resolve the recording theme and honor terminal color settings" do
    palette = Enum.map_join(0..15, ":", fn i -> if i == 9, do: "#abcdef", else: "#123456" end)

    recording =
      build(:asciicast,
        term_theme_name: "original",
        term_theme_fg: "#ffffff",
        term_theme_bg: "#000000",
        term_theme_palette: palette,
        term_bold_is_bright: true,
        term_adaptive_palette: true,
        snapshot:
          Snapshot.from_segments([
            [{"█", %{"fg" => 1, "bold" => true}, 1}, {"█", %{"fg" => 21}, 1}]
          ])
      )

    for variant <- [:full, :thumbnail] do
      svg =
        recording |> then(&RecordingSVG.render_to_iodata(variant, &1)) |> IO.iodata_to_binary()

      png = embedded_png(svg)
      assert cell_contains_color?(png, 0, 0, {171, 205, 239})
      assert cell_contains_color?(png, 1, 0, {18, 52, 86})
    end
  end

  defp embedded_png(svg) do
    [_, encoded] = Regex.run(~r/href="data:image\/png;base64,([^"]+)"/, svg)
    decode_png(Base.decode64!(encoded))
  end
end
