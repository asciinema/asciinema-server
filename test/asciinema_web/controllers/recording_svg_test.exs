defmodule AsciinemaWeb.RecordingSvgTest do
  use ExUnit.Case, async: true
  import Asciinema.Factory
  import Asciinema.PngUtil
  alias Asciinema.Colors
  alias Asciinema.Ecto.Type.Snapshot, as: EctoSnapshot
  alias Asciinema.Recordings.Snapshot
  alias AsciinemaWeb.RecordingSVG

  describe "full/1" do
    test "renders SVG document" do
      asciicast =
        build(:asciicast,
          snapshot: snapshot([[["foobar", %{}, 1]], [["bazqux", %{}, 1]]])
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
            snapshot([
              [["foo", %{"fg" => [16, 32, 48]}, 1], ["bar", %{"bg" => "rgb(64,80,96)"}, 1]],
              [["baz", %{"fg" => "#708090"}, 1]]
            ])
        )

      svg = render_full(asciicast)

      assert svg =~ "#102030"
      assert svg =~ "#708090"

      png = decode_embedded_png(svg)
      assert rgb_at_cell(png, 3, 0) == {64, 80, 96}
    end

    test "preserves leading and repeated spaces in SVG text runs" do
      svg =
        build(:asciicast, snapshot: snapshot([[["  foo  bar", %{}, 1]]]))
        |> render_full()

      assert svg =~ ~s(xml:space="preserve")
      assert svg =~ "  foo  bar"
    end

    @tag :rsvg
    test "preserves spaces when rasterized with librsvg" do
      one_space =
        build(:asciicast, snapshot: snapshot([[["foo bar", %{}, 1]]]))
        |> render_full()
        |> rasterize_svg()

      two_spaces =
        build(:asciicast, snapshot: snapshot([[["foo  bar", %{}, 1]]]))
        |> render_full()
        |> rasterize_svg()

      no_leading_spaces =
        build(:asciicast, snapshot: snapshot([[["foo", %{}, 1]]]))
        |> render_full()
        |> rasterize_svg()

      leading_spaces =
        build(:asciicast, snapshot: snapshot([[["  foo", %{}, 1]]]))
        |> render_full()
        |> rasterize_svg()

      refute one_space == two_spaces
      refute no_leading_spaces == leading_spaces
    end

    test "clips background segments to configured terminal width" do
      asciicast =
        build(:asciicast,
          term_cols_override: 3,
          term_rows_override: 1,
          snapshot: snapshot([[["abcdefghij", %{"bg" => "#112233"}, 1]]])
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      assert png.width == 24
      assert png.height == 24
      assert rgb_at(png, 0, 0) == {17, 34, 51}
      assert rgb_at(png, 23, 23) == {17, 34, 51}
    end

    test "routes representative rasterized glyph groups to embedded PNG layer" do
      fg = {255, 85, 0}
      sextant_ul = <<0x1FB00::utf8>>
      line = "█│┃╵╷╹╻■" <> sextant_ul

      asciicast =
        build(:asciicast,
          term_cols: 9,
          term_rows: 1,
          snapshot: snapshot([[[line, %{"fg" => "#ff5500"}, 1]]])
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      # block elements
      refute svg =~ "█"
      assert cell_contains_color?(png, 0, 0, fg)

      # box verticals
      refute svg =~ "│"
      refute svg =~ "┃"
      refute svg =~ "╵"
      refute svg =~ "╷"
      refute svg =~ "╹"
      refute svg =~ "╻"
      assert cell_contains_color?(png, 1, 0, fg)
      assert cell_contains_color?(png, 2, 0, fg)
      assert cell_contains_color?(png, 3, 0, fg)
      assert cell_contains_color?(png, 4, 0, fg)
      assert cell_contains_color?(png, 5, 0, fg)
      assert cell_contains_color?(png, 6, 0, fg)

      # black square
      refute svg =~ "■"
      assert cell_contains_color?(png, 7, 0, fg)

      # sextants
      refute svg =~ sextant_ul
      assert cell_contains_color?(png, 8, 0, fg)
    end

    test "rasterizes block symbols into the embedded PNG" do
      asciicast =
        build(:asciicast,
          term_cols: 2,
          term_rows: 1,
          snapshot: snapshot([[["▀█", %{"fg" => "#aa5500"}, 1]]])
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      assert png.width == 16
      assert png.height == 24
      refute svg =~ "▀"
      refute svg =~ "█"
      assert cell_contains_color?(png, 0, 0, {170, 85, 0})
      assert cell_contains_color?(png, 1, 0, {170, 85, 0})
    end

    test "keeps adjacent block cells seamless in raster output" do
      asciicast =
        build(:asciicast,
          term_cols: 2,
          term_rows: 1,
          snapshot: snapshot([[["██", %{"fg" => "#3366cc"}, 1]]])
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      assert rgb_at(png, 7, 12) == {51, 102, 204}
      assert rgb_at(png, 8, 12) == {51, 102, 204}
    end

    test "renders box drawing vertical lines in mosaic layer and excludes them from text layer" do
      asciicast =
        build(:asciicast,
          term_cols: 2,
          term_rows: 1,
          snapshot: snapshot([[["│┃", %{"fg" => "#ff5500"}, 1]]])
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      refute svg =~ "│"
      refute svg =~ "┃"
      assert cell_contains_color?(png, 0, 0, {255, 85, 0})
      assert cell_contains_color?(png, 1, 0, {255, 85, 0})
    end

    test "renders box drawing vertical half-lines in mosaic layer and excludes them from text layer" do
      half_lines = <<0x2575::utf8, 0x2577::utf8, 0x2579::utf8, 0x257B::utf8>>

      asciicast =
        build(:asciicast,
          term_cols: 4,
          term_rows: 1,
          snapshot: snapshot([[[half_lines, %{"fg" => "#ff5500"}, 1]]])
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      refute svg =~ <<0x2575::utf8>>
      refute svg =~ <<0x2577::utf8>>
      refute svg =~ <<0x2579::utf8>>
      refute svg =~ <<0x257B::utf8>>
      assert cell_contains_color?(png, 0, 0, {255, 85, 0})
      assert cell_contains_color?(png, 1, 0, {255, 85, 0})
      assert cell_contains_color?(png, 2, 0, {255, 85, 0})
      assert cell_contains_color?(png, 3, 0, {255, 85, 0})
    end

    test "renders black square in mosaic layer and excludes it from text layer" do
      asciicast =
        build(:asciicast,
          term_cols: 3,
          term_rows: 1,
          snapshot: snapshot([[["a■b", %{"fg" => "#ff5500"}, 1]]])
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      refute svg =~ "■"
      assert cell_contains_color?(png, 1, 0, {255, 85, 0})
      refute cell_contains_color?(png, 0, 0, {255, 85, 0})
      refute cell_contains_color?(png, 2, 0, {255, 85, 0})
    end

    test "renders sextant in mosaic layer and excludes it from text layer" do
      sextant_ul = <<0x1FB00::utf8>>

      asciicast =
        build(:asciicast,
          term_cols: 1,
          term_rows: 1,
          snapshot: snapshot([[[sextant_ul, %{"fg" => "#00aaee"}, 1]]])
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      refute svg =~ sextant_ul
      assert png.width == 8
      assert png.height == 24
      assert cell_contains_color?(png, 0, 0, {0, 170, 238})
    end

    test "uses theme default fg for inverse cell background" do
      asciicast =
        build(:asciicast,
          term_theme_name: "asciinema",
          term_cols: 1,
          term_rows: 1,
          snapshot: snapshot([[["X", %{"inverse" => true}, 1]]])
        )

      svg = render_full(asciicast)
      png = decode_embedded_png(svg)

      # asciinema theme default fg is #cccccc
      assert rgb_at_cell(png, 0, 0) == {204, 204, 204}
    end

    test "uses fixed palette for indexed 256 colors by default" do
      asciicast =
        build(:asciicast,
          term_theme_name: "dracula",
          term_adaptive_palette: false,
          term_cols: 13,
          term_rows: 2,
          snapshot: palette_index_snapshot()
        )

      png = asciicast |> render_full() |> decode_embedded_png()

      assert_palette_rows(png, [
        "#000000",
        "#0000ff",
        "#00ff00",
        "#00ffff",
        "#ff0000",
        "#ff00ff",
        "#ffff00",
        "#ffffff",
        "#878787",
        "#afafaf",
        "#080808",
        "#767676",
        "#eeeeee"
      ])
    end

    test "uses adaptive palette for indexed 256 colors when enabled" do
      asciicast =
        build(:asciicast,
          term_theme_name: "dracula",
          term_adaptive_palette: true,
          term_cols: 13,
          term_rows: 2,
          snapshot: palette_index_snapshot()
        )

      png = asciicast |> render_full() |> decode_embedded_png()

      assert_palette_rows(png, [
        "#282a36",
        "#bd93f9",
        "#50fa7b",
        "#8be9fd",
        "#ff5555",
        "#ff79c6",
        "#f1fa8c",
        "#f8f8f2",
        "#ab9c99",
        "#d1c1bc",
        "#2f313d",
        "#84868b",
        "#efefea"
      ])
    end
  end

  describe "thumbnail/1" do
    test "renders SVG element" do
      asciicast =
        build(:asciicast,
          snapshot: snapshot([[["foobar", %{}, 1]], [["bazqux", %{}, 1]]])
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
          snapshot: snapshot([[["x", %{}, 1]]])
        )

      svg = render_thumbnail(asciicast)
      png = decode_embedded_png(svg)

      assert png.width == 80 * 8
      assert png.height == 15 * 24
    end

    test "uses square corners" do
      asciicast =
        build(:asciicast,
          snapshot: snapshot([[["x", %{}, 1]]])
        )

      svg = render_thumbnail(asciicast)

      assert svg =~ ~s(rx="0")
      assert svg =~ ~s(ry="0")
    end

    test "does not include logo" do
      asciicast =
        build(:asciicast,
          snapshot: snapshot([[["x", %{}, 1]]])
        )

      svg = render_thumbnail(asciicast)

      refute logo_present(svg)
    end

    test "does not include XML declaration by default" do
      asciicast =
        build(:asciicast,
          snapshot: snapshot([[["x", %{}, 1]]])
        )

      svg = render_thumbnail(asciicast)

      refute svg =~ "<?xml"
    end

    test "includes XML declaration when standalone" do
      asciicast =
        build(:asciicast,
          snapshot: snapshot([[["x", %{}, 1]]])
        )

      svg = render_thumbnail(asciicast, standalone: true)

      assert svg =~ "<?xml"
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

  defp rasterize_svg(svg) do
    path = Briefly.create!(extname: ".svg")
    File.write!(path, svg)
    {png, 0} = System.cmd("rsvg-convert", [path])

    png
  end

  defp rgb_at_cell(png, x, y), do: rgb_at(png, x * 8, y * 24)

  defp logo_present(svg), do: svg =~ "small-triangle-mask"

  defp snapshot(lines) do
    {:ok, snapshot} = EctoSnapshot.cast({lines, nil})
    snapshot
  end

  defp palette_index_snapshot do
    indices = [16, 21, 46, 51, 196, 201, 226, 231, 102, 145, 232, 243, 255]
    fg_row = Enum.map(indices, &{"█", %{"fg" => &1}, 1})
    bg_row = Enum.map(indices, &{" ", %{"bg" => &1}, 1})

    Snapshot.new([fg_row, bg_row])
  end

  defp assert_palette_rows(png, colors) do
    colors
    |> Enum.map(&Colors.parse/1)
    |> Enum.with_index()
    |> Enum.each(fn {color, x} ->
      assert rgb_at_cell(png, x, 0) == color
      assert rgb_at_cell(png, x, 1) == color
    end)
  end
end
