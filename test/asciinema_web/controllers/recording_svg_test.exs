defmodule AsciinemaWeb.RecordingSvgTest do
  use ExUnit.Case, async: true
  import Asciinema.Factory
  import Asciinema.PngUtil
  alias Asciinema.Recordings.Snapshot
  alias AsciinemaWeb.RecordingSVG

  describe "full/1" do
    test "renders SVG document" do
      asciicast =
        build(:asciicast,
          snapshot: Snapshot.new([[["foobar", %{}, 1]], [["bazqux", %{}, 1]]], :segments)
        )

      svg = render_full(asciicast)

      assert svg =~ ~r/^<\?xml.+foobar.+bazqux/s
      assert svg =~ "data:image/png;base64,"
      assert logo_present(svg)
    end

    test "supports rgb(...) color in fg/bg text attrs" do
      asciicast =
        build(:asciicast,
          snapshot:
            Snapshot.new(
              [
                [["foo", %{"fg" => [16, 32, 48]}, 1], ["bar", %{"bg" => "rgb(64,80,96)"}, 1]],
                [["baz", %{"fg" => "#708090"}, 1]]
              ],
              :segments
            )
        )

      svg = render_full(asciicast)

      assert svg =~ "#102030"
      assert svg =~ "#708090"

      png = decode_embedded_png(svg)
      assert rgb_at_cell(png, 3, 0) == {64, 80, 96}
    end

    test "clips background segments to configured terminal width" do
      asciicast =
        build(:asciicast,
          term_cols_override: 3,
          term_rows_override: 1,
          snapshot: Snapshot.new([[["abcdefghij", %{"bg" => "#112233"}, 1]]], :segments)
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      assert png.width == 24
      assert png.height == 24
      assert rgb_at(png, 0, 0) == {17, 34, 51}
      assert rgb_at(png, 23, 23) == {17, 34, 51}
    end

    test "rasterizes block symbols into the embedded PNG" do
      asciicast =
        build(:asciicast,
          term_cols: 2,
          term_rows: 1,
          snapshot: Snapshot.new([[["▀█", %{"fg" => "#aa5500"}, 1]]], :segments)
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      assert png.width == 16
      assert png.height == 24
      assert rgb_at(png, 0, 0) == {170, 85, 0}
      assert rgb_at(png, 0, 23) == {18, 19, 20}
      assert rgb_at(png, 8, 23) == {170, 85, 0}
    end

    test "keeps adjacent block cells seamless in raster output" do
      asciicast =
        build(:asciicast,
          term_cols: 2,
          term_rows: 1,
          snapshot: Snapshot.new([[["██", %{"fg" => "#3366cc"}, 1]]], :segments)
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      assert rgb_at(png, 7, 12) == {51, 102, 204}
      assert rgb_at(png, 8, 12) == {51, 102, 204}
    end

    test "renders black square in mosaic layer and excludes it from text layer" do
      asciicast =
        build(:asciicast,
          term_cols: 3,
          term_rows: 1,
          snapshot: Snapshot.new([[["a■b", %{"fg" => "#ff5500"}, 1]]], :segments)
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      refute svg =~ "■"
      assert rgb_at(png, 8, 0) == {18, 19, 20}
      assert rgb_at(png, 8, 6) == {255, 85, 0}
      assert rgb_at(png, 8, 17) == {255, 85, 0}
      assert rgb_at(png, 8, 23) == {18, 19, 20}
      assert rgb_at_cell(png, 0, 0) == {18, 19, 20}
      assert rgb_at_cell(png, 2, 0) == {18, 19, 20}
    end

    test "renders sextant in mosaic layer and excludes it from text layer" do
      sextant_ul = <<0x1FB00::utf8>>

      asciicast =
        build(:asciicast,
          term_cols: 1,
          term_rows: 1,
          snapshot: Snapshot.new([[[sextant_ul, %{"fg" => "#00aaee"}, 1]]], :segments)
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      refute svg =~ sextant_ul
      assert png.width == 8
      assert png.height == 24
      assert rgb_at(png, 0, 0) == {0, 170, 238}
      assert rgb_at(png, 3, 7) == {0, 170, 238}
      assert rgb_at(png, 4, 0) == {18, 19, 20}
      assert rgb_at(png, 0, 8) == {18, 19, 20}
    end

    test "uses theme default fg for inverse cell background" do
      asciicast =
        build(:asciicast,
          term_theme_name: "asciinema",
          term_cols: 1,
          term_rows: 1,
          snapshot: Snapshot.new([[["X", %{"inverse" => true}, 1]]], :segments)
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      # asciinema theme default fg is #cccccc
      assert rgb_at_cell(png, 0, 0) == {204, 204, 204}
    end
  end

  describe "thumbnail/1" do
    test "renders SVG element" do
      asciicast =
        build(:asciicast,
          snapshot: Snapshot.new([[["foobar", %{}, 1]], [["bazqux", %{}, 1]]], :segments)
        )

      svg = render_thumbnail(asciicast)

      assert svg =~ "foobar"
      assert svg =~ "bazqux"
      assert svg =~ "data:image/png;base64,"
    end

    test "crops snapshot to 80x15" do
      asciicast =
        build(:asciicast,
          term_cols: 200,
          term_rows: 50,
          snapshot: Snapshot.new([[["x", %{}, 1]]], :segments)
        )

      svg = render_thumbnail(asciicast)
      png = decode_embedded_png(svg)

      assert png.width == 80 * 8
      assert png.height == 15 * 24
    end

    test "uses square corners" do
      asciicast =
        build(:asciicast,
          snapshot: Snapshot.new([[["x", %{}, 1]]], :segments)
        )

      svg = render_thumbnail(asciicast)

      assert svg =~ ~s(rx="0")
      assert svg =~ ~s(ry="0")
    end

    test "does not include logo" do
      asciicast =
        build(:asciicast,
          snapshot: Snapshot.new([[["x", %{}, 1]]], :segments)
        )

      svg = render_thumbnail(asciicast)

      refute logo_present(svg)
    end

    test "does not include XML declaration by default" do
      asciicast =
        build(:asciicast,
          snapshot: Snapshot.new([[["x", %{}, 1]]], :segments)
        )

      svg = render_thumbnail(asciicast)

      refute svg =~ "<?xml"
    end

    test "includes XML declaration when standalone" do
      asciicast =
        build(:asciicast,
          snapshot: Snapshot.new([[["x", %{}, 1]]], :segments)
        )

      svg = render_thumbnail(asciicast, standalone: true)

      assert svg =~ "<?xml"
    end
  end

  @lines [
    [{" foo bar  baz", %{"bg" => 2}, 1}, {"!", %{"fg" => 1}, 1}],
    [{"qux", %{"bg" => "#102030"}, 1}, {"连", %{}, 2}, {"接", %{}, 2}]
  ]

  describe "fg_coords/1" do
    test "excludes whitespace" do
      coords =
        RecordingSVG.fg_coords(@lines)

      assert coords == [
               %{
                 y: 0,
                 segments: [
                   %{text: "foo bar", attrs: %{"bg" => 2}, x: 1, width: 7},
                   %{text: "baz", attrs: %{"bg" => 2}, x: 10, width: 3},
                   %{text: "!", attrs: %{"fg" => 1}, x: 13, width: 1}
                 ]
               },
               %{
                 y: 1,
                 segments: [
                   %{text: "qux", attrs: %{"bg" => "#102030"}, x: 0, width: 3},
                   %{text: "连", attrs: %{}, x: 3, width: 2},
                   %{text: "接", attrs: %{}, x: 5, width: 2}
                 ]
               }
             ]
    end
  end

  describe "bg_coords/1" do
    test "excludes segments with default background" do
      coords =
        RecordingSVG.bg_coords(@lines)

      assert coords == [
               %{
                 y: 0,
                 segments: [
                   %{attrs: %{"bg" => 2}, x: 0, width: 13}
                 ]
               },
               %{
                 y: 1,
                 segments: [
                   %{attrs: %{"bg" => "#102030"}, x: 0, width: 3}
                 ]
               }
             ]
    end
  end

  defp render_full(asciicast) do
    Phoenix.LiveViewTest.rendered_to_string(RecordingSVG.full(%{asciicast: asciicast}))
  end

  defp render_thumbnail(asciicast, opts \\ []) do
    Phoenix.LiveViewTest.rendered_to_string(
      RecordingSVG.thumbnail(%{
        asciicast: asciicast,
        standalone: Keyword.get(opts, :standalone, false)
      })
    )
  end

  defp decode_embedded_png(svg) do
    [_, encoded] = Regex.run(~r/href="data:image\/png;base64,([^"]+)"/, svg)
    decode_png(Base.decode64!(encoded))
  end

  defp rgb_at_cell(png, x, y), do: rgb_at(png, x * 8, y * 24)

  defp logo_present(svg), do: svg =~ "small-triangle-mask"
end
