defmodule AsciinemaWeb.TerminalSVGTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest, only: [render_component: 2]
  import Asciinema.PngUtil
  alias Asciinema.Colors
  alias Asciinema.Recordings.Snapshot
  alias Asciinema.Themes
  alias AsciinemaWeb.TerminalSVG

  test "missing snapshots render the same empty terminal as an empty snapshot" do
    for renderer <- [&TerminalSVG.preview/1, &TerminalSVG.thumbnail/1] do
      empty = terminal(snapshot: Snapshot.from_segments([]))
      missing = terminal(snapshot: nil)
      assert render_component(renderer, missing) == render_component(renderer, empty)
    end
  end

  describe "preview/1" do
    test "Powerline separators veto only their edge row's vertical extension" do
      attrs = %{"bg" => "#123456"}

      for row <- [0, 1], cp <- [0xE0B0, 0xE0C8, 0xE0CA, 0xE0CC, 0xE0D2, 0xE0D4] do
        rows =
          List.replace_at([[{"   ", attrs, 1}], [{"   ", attrs, 1}]], row, [
            {" #{<<cp::utf8>>} ", attrs, 1}
          ])

        png =
          terminal(
            cols: 3,
            rows: 2,
            theme: Themes.named_theme("asciinema"),
            snapshot: Snapshot.from_segments(rows)
          )
          |> render_full()
          |> decode_embedded_png()

        for x <- 0..(png.width - 1) do
          assert rgb_at(png, x, 0) == if(row == 0, do: {18, 19, 20}, else: {18, 52, 86})

          assert rgb_at(png, x, png.height - 1) ==
                   if(row == 1, do: {18, 19, 20}, else: {18, 52, 86})
        end

        for y <- [24, 48] do
          assert rgb_at(png, 0, y) == {18, 52, 86}
          assert rgb_at(png, png.width - 1, y) == {18, 52, 86}
        end
      end
    end

    test "ignores Powerline symbols outside edge rows or columns and unlisted codepoints" do
      for {text, row} <- [
            {" \uE0B0 ", 1},
            {"   \uE0B0", 0},
            {" \uE0C9 ", 0},
            {" \uE0CB ", 0},
            {" \uE0D3 ", 0},
            {" \uE0D5 ", 0}
          ] do
        attrs = %{"bg" => "#123456"}
        rows = List.duplicate([{"   ", attrs, 1}], 3) |> List.replace_at(row, [{text, attrs, 1}])

        png =
          terminal(
            cols: 3,
            rows: 3,
            theme: Themes.named_theme("asciinema"),
            snapshot: Snapshot.from_segments(rows)
          )
          |> render_full()
          |> decode_embedded_png()

        assert rgb_at(png, 0, 0) == {18, 52, 86}
        assert rgb_at(png, 0, png.height - 1) == {18, 52, 86}
      end
    end

    test "extends underlying colors rather than cursor paint into padding" do
      attrs = %{"fg" => "#abcdef", "bg" => "#123456"}

      for {segments, padding, cursor_color} <- [
            {[{"  ", attrs, 1}], {18, 52, 86}, {171, 205, 239}},
            {[{"  ", Map.put(attrs, "inverse", true), 1}], {171, 205, 239}, {18, 52, 86}},
            {[{"全", attrs, 2}], {18, 52, 86}, {171, 205, 239}},
            {[{"██", attrs, 1}], {171, 205, 239}, {18, 52, 86}},
            {[{"░░", attrs, 1}], {18, 52, 86}, {132, 166, 200}},
            {[{"▒▒", attrs, 1}], {18, 52, 86}, {94, 128, 162}},
            {[{"▓▓", attrs, 1}], {18, 52, 86}, {56, 90, 124}},
            {[{"▀▀", attrs, 1}], {18, 52, 86}, {171, 205, 239}},
            {[], {18, 19, 20}, {204, 204, 204}}
          ] do
        png =
          terminal(
            cols: 2,
            rows: 1,
            theme: Themes.named_theme("asciinema"),
            snapshot: Snapshot.from_segments([segments], {1, 0})
          )
          |> render_full()
          |> decode_embedded_png()

        # Bottom half also checks the background of the partial block.
        assert grid_rgb_at(png, 8, 18) == cursor_color

        for {x, y} <- [{0, 0}, {16, 0}, {31, 0}, {0, 24}, {31, 24}, {16, 47}, {31, 47}] do
          assert rgb_at(png, x, y) == padding
        end
      end
    end

    test "renders a pending-wrap cursor on the last visible cell" do
      {:ok, vt} = Asciinema.Vt.new(3, 1, 0)
      Asciinema.Vt.feed(vt, "abc")
      {rows, cursor} = Asciinema.Vt.dump_screen(vt)
      assert cursor == {2, 0}

      png =
        terminal(
          cols: 3,
          rows: 1,
          theme: Themes.named_theme("asciinema"),
          snapshot: Snapshot.from_segments(rows, cursor)
        )
        |> render_full()
        |> decode_embedded_png()

      assert rgb_at_cell(png, 2, 0) == {204, 204, 204}
      refute rgb_at_cell(png, 1, 0) == {204, 204, 204}
    end

    test "renders implicit blank cursor cells like explicit spaces" do
      for {sparse, padded, cursor} <- [
            {[[{"a", %{}, 1}], [], []], [[{"a", %{}, 1}], [], [{"   ", %{}, 1}]], {2, 2}},
            {[[{"a", %{}, 1}]], [[{"a   ", %{}, 1}]], {3, 0}},
            {[], [[], [{" ", %{}, 1}]], {0, 1}}
          ] do
        pngs =
          for rows <- [sparse, padded] do
            terminal(
              cols: 4,
              rows: 3,
              theme: Themes.named_theme("asciinema"),
              snapshot: Snapshot.from_segments(rows, cursor)
            )
            |> render_full()
            |> decode_embedded_png()
          end

        [png, padded_png] = pngs
        assert png == padded_png
        {x, y} = cursor
        assert rgb_at_cell(png, x, y) == {204, 204, 204}
      end
    end

    test "renders the cursor over original cell colors including inverse video" do
      for {inverse, expected} <- [{false, {204, 204, 204}}, {true, {18, 52, 86}}] do
        snapshot =
          Snapshot.from_segments(
            [[["  ", %{"bg" => "#123456", "inverse" => inverse}, 1]]],
            {0, 0}
          )

        terminal =
          terminal(
            theme: Themes.named_theme("asciinema"),
            cols: 2,
            rows: 1,
            snapshot: snapshot
          )

        png = terminal |> render_full() |> decode_embedded_png()
        assert rgb_at_cell(png, 0, 0) == expected
        assert snapshot.cursor == {0, 0}
      end
    end

    test "renders terminal content without branding" do
      terminal =
        terminal(snapshot: snapshot([[["foobar", %{}, 1]], [["bazqux", %{}, 1]]]))

      svg = render_full(terminal)

      assert svg =~ ~r/foobar.+bazqux/s
      assert svg =~ "data:image/png;base64,"
      refute logo_present(svg)
    end

    test "supports rgb(...) color in fg/bg text attrs" do
      terminal =
        terminal(
          snapshot:
            snapshot([
              [["foo", %{"fg" => [16, 32, 48]}, 1], ["bar", %{"bg" => "rgb(64,80,96)"}, 1]],
              [["baz", %{"fg" => "#708090"}, 1]]
            ])
        )

      svg = render_full(terminal)

      assert svg =~ "#102030"
      assert svg =~ "#708090"

      png = decode_embedded_png(svg)
      assert rgb_at_cell(png, 3, 0) == {64, 80, 96}
    end

    test "preserves leading and repeated spaces in SVG text runs" do
      svg =
        terminal(snapshot: snapshot([[["  foo  bar", %{}, 1]]]))
        |> render_full()

      assert svg =~ ~s(xml:space="preserve")
      assert svg =~ "  foo  bar"
    end

    test "clips background segments to configured terminal width" do
      terminal =
        terminal(
          cols: 3,
          rows: 1,
          snapshot: snapshot([[["abcdefghij", %{"bg" => "#112233"}, 1]]])
        )

      svg = render_full(terminal)
      png = decode_embedded_png(svg)

      assert png.width == 40
      assert png.height == 48
      assert rgb_at(png, 0, 0) == {17, 34, 51}
      assert rgb_at(png, 23, 23) == {17, 34, 51}
    end

    test "routes only supported rasterized glyph groups to embedded PNG layer" do
      fg = {255, 85, 0}
      sextant_ul = <<0x1FB00::utf8>>
      line = "█│┃╵╷╹╻■" <> sextant_ul

      terminal =
        terminal(
          cols: 9,
          rows: 1,
          snapshot: snapshot([[[line, %{"fg" => "#ff5500"}, 1]]])
        )

      svg = render_full(terminal)
      png = decode_embedded_png(svg)

      # block elements
      refute svg =~ "█"
      assert cell_contains_color?(png, 0, 0, fg)

      # light verticals stay in text, heavy ones are rasterized
      assert svg =~ "│"
      refute svg =~ "┃"
      assert svg =~ "╵"
      assert svg =~ "╷"
      refute svg =~ "╹"
      refute svg =~ "╻"
      refute cell_contains_color?(png, 1, 0, fg)
      assert cell_contains_color?(png, 2, 0, fg)
      refute cell_contains_color?(png, 3, 0, fg)
      refute cell_contains_color?(png, 4, 0, fg)
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
      terminal =
        terminal(
          cols: 2,
          rows: 1,
          snapshot: snapshot([[["▀█", %{"fg" => "#aa5500"}, 1]]])
        )

      svg = render_full(terminal)
      png = decode_embedded_png(svg)

      assert png.width == 32
      assert png.height == 48
      refute svg =~ "▀"
      refute svg =~ "█"
      assert cell_contains_color?(png, 0, 0, {170, 85, 0})
      assert cell_contains_color?(png, 1, 0, {170, 85, 0})
    end

    test "keeps adjacent block cells seamless in raster output" do
      terminal =
        terminal(
          cols: 2,
          rows: 1,
          snapshot: snapshot([[["██", %{"fg" => "#3366cc"}, 1]]])
        )

      svg = render_full(terminal)
      png = decode_embedded_png(svg)

      assert grid_rgb_at(png, 7, 12) == {51, 102, 204}
      assert grid_rgb_at(png, 8, 12) == {51, 102, 204}
    end

    test "renders heavy box drawing vertical lines in mosaic layer" do
      terminal =
        terminal(
          cols: 2,
          rows: 1,
          snapshot: snapshot([[["│┃", %{"fg" => "#ff5500"}, 1]]])
        )

      svg = render_full(terminal)
      png = decode_embedded_png(svg)

      assert svg =~ "│"
      refute svg =~ "┃"
      refute cell_contains_color?(png, 0, 0, {255, 85, 0})
      assert cell_contains_color?(png, 1, 0, {255, 85, 0})
    end

    test "renders heavy box drawing vertical half-lines in mosaic layer" do
      half_lines = <<0x2575::utf8, 0x2577::utf8, 0x2579::utf8, 0x257B::utf8>>

      terminal =
        terminal(
          cols: 4,
          rows: 1,
          snapshot: snapshot([[[half_lines, %{"fg" => "#ff5500"}, 1]]])
        )

      svg = render_full(terminal)
      png = decode_embedded_png(svg)

      assert svg =~ <<0x2575::utf8>>
      assert svg =~ <<0x2577::utf8>>
      refute svg =~ <<0x2579::utf8>>
      refute svg =~ <<0x257B::utf8>>
      refute cell_contains_color?(png, 0, 0, {255, 85, 0})
      refute cell_contains_color?(png, 1, 0, {255, 85, 0})
      assert cell_contains_color?(png, 2, 0, {255, 85, 0})
      assert cell_contains_color?(png, 3, 0, {255, 85, 0})
    end

    test "renders black square in mosaic layer and excludes it from text layer" do
      terminal =
        terminal(
          cols: 3,
          rows: 1,
          snapshot: snapshot([[["a■b", %{"fg" => "#ff5500"}, 1]]])
        )

      svg = render_full(terminal)
      png = decode_embedded_png(svg)

      refute svg =~ "■"
      assert cell_contains_color?(png, 1, 0, {255, 85, 0})
      refute cell_contains_color?(png, 0, 0, {255, 85, 0})
      refute cell_contains_color?(png, 2, 0, {255, 85, 0})
    end

    test "renders sextant in mosaic layer and excludes it from text layer" do
      sextant_ul = <<0x1FB00::utf8>>

      terminal =
        terminal(
          cols: 1,
          rows: 1,
          snapshot: snapshot([[[sextant_ul, %{"fg" => "#00aaee"}, 1]]])
        )

      svg = render_full(terminal)
      png = decode_embedded_png(svg)

      refute svg =~ sextant_ul
      assert png.width == 24
      assert png.height == 48
      assert cell_contains_color?(png, 0, 0, {0, 170, 238})
    end

    test "routes full Powerline range (U+E0B0..U+E0BF) to vector SVG layer" do
      fg = {255, 85, 0}
      codepoints = Enum.to_list(0xE0B0..0xE0BF)
      line = for cp <- codepoints, into: "", do: <<cp::utf8>>

      terminal =
        terminal(
          cols: length(codepoints),
          rows: 1,
          snapshot: snapshot([[[line, %{"fg" => "#ff5500"}, 1]]])
        )

      svg = render_full(terminal)
      png = decode_embedded_png(svg)

      for cp <- codepoints do
        char = <<cp::utf8>>
        refute svg =~ char, "expected SVG not to render literal #{inspect(char)}"
      end

      for col <- 0..(length(codepoints) - 1) do
        refute cell_contains_color?(png, col, 0, fg),
               "expected cell #{col} to only contain background in embedded PNG"
      end
    end

    test "uses theme default fg for inverse cell background" do
      terminal =
        terminal(
          theme: Themes.named_theme("asciinema"),
          cols: 1,
          rows: 1,
          snapshot: snapshot([[["X", %{"inverse" => true}, 1]]])
        )

      svg = render_full(terminal)
      png = decode_embedded_png(svg)

      # asciinema theme default fg is #cccccc
      assert rgb_at_cell(png, 0, 0) == {204, 204, 204}
    end

    test "uses fixed palette for indexed 256 colors by default" do
      terminal =
        terminal(
          theme: Themes.named_theme("dracula"),
          adaptive_palette: false,
          cols: 13,
          rows: 2,
          snapshot: palette_index_snapshot()
        )

      png = terminal |> render_full() |> decode_embedded_png()

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
      terminal =
        terminal(
          theme: Themes.named_theme("dracula"),
          adaptive_palette: true,
          cols: 13,
          rows: 2,
          snapshot: palette_index_snapshot()
        )

      png = terminal |> render_full() |> decode_embedded_png()

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
    test "checks Powerline symbols on the cropped boundary rows" do
      attrs = %{"bg" => "#123456"}

      rows =
        List.duplicate([{String.duplicate(" ", 80), attrs, 1}], 17)
        |> List.replace_at(2, [{" \uE0B0" <> String.duplicate(" ", 78), attrs, 1}])

      png =
        terminal(
          cols: 80,
          rows: 17,
          theme: Themes.named_theme("asciinema"),
          snapshot: Snapshot.from_segments(rows)
        )
        |> render_thumbnail()
        |> decode_embedded_png()

      assert rgb_at(png, 0, 0) == {18, 19, 20}
      assert rgb_at(png, 0, png.height - 1) == {18, 52, 86}
    end

    test "renders a cursor on an empty row retained by thumbnail cropping" do
      png =
        terminal(
          theme: Themes.named_theme("asciinema"),
          snapshot: Snapshot.from_segments([[{"a", %{}, 1}], [], []], {2, 2})
        )
        |> render_thumbnail()
        |> decode_embedded_png()

      assert rgb_at_cell(png, 2, 2) == {204, 204, 204}
    end

    test "renders SVG element" do
      terminal =
        terminal(snapshot: snapshot([[["foobar", %{}, 1]], [["bazqux", %{}, 1]]]))

      svg = render_thumbnail(terminal)

      assert svg =~ "foobar"
      assert svg =~ "bazqux"
      assert svg =~ "data:image/png;base64,"
    end

    test "crops snapshot to 80x15" do
      terminal =
        terminal(
          cols: 200,
          rows: 50,
          snapshot: snapshot([[["x", %{}, 1]]])
        )

      svg = render_thumbnail(terminal)
      png = decode_embedded_png(svg)

      assert png.width == 82 * 8
      assert png.height == 16 * 24
    end

    test "uses square corners" do
      terminal =
        terminal(snapshot: snapshot([[["x", %{}, 1]]]))

      svg = render_thumbnail(terminal)

      assert svg =~ ~s(rx="0")
      assert svg =~ ~s(ry="0")
    end

    test "does not include logo" do
      terminal =
        terminal(snapshot: snapshot([[["x", %{}, 1]]]))

      svg = render_thumbnail(terminal)

      refute logo_present(svg)
    end

    test "does not include XML declaration by default" do
      terminal =
        terminal(snapshot: snapshot([[["x", %{}, 1]]]))

      svg = render_thumbnail(terminal)

      refute svg =~ "<?xml"
    end

    test "includes XML declaration when standalone" do
      terminal =
        terminal(snapshot: snapshot([[["x", %{}, 1]]]))

      svg = render_thumbnail(terminal, standalone: true)

      assert svg =~ "<?xml"
    end
  end

  defp terminal(opts) do
    Map.merge(
      %{cols: 80, rows: 24, theme: Themes.named_theme("asciinema-neo-dark")},
      Map.new(opts)
    )
  end

  defp render_full(terminal) do
    render_component(&TerminalSVG.preview/1, terminal)
  end

  defp render_thumbnail(terminal, opts \\ []) do
    render_component(
      &TerminalSVG.thumbnail/1,
      Map.put(terminal, :standalone, Keyword.get(opts, :standalone, false))
    )
  end

  defp decode_embedded_png(svg) do
    [_, encoded] = Regex.run(~r/href="data:image\/png;base64,([^"]+)"/, svg)
    decode_png(Base.decode64!(encoded))
  end

  defp rgb_at_cell(png, x, y), do: grid_rgb_at(png, x * 8, y * 24)

  defp logo_present(svg), do: svg =~ "small-triangle-mask"

  defp snapshot(lines) do
    Snapshot.from_segments(lines)
  end

  defp palette_index_snapshot do
    indices = [16, 21, 46, 51, 196, 201, 226, 231, 102, 145, 232, 243, 255]
    fg_row = Enum.map(indices, &{"█", %{"fg" => &1}, 1})
    bg_row = Enum.map(indices, &{" ", %{"bg" => &1}, 1})

    Snapshot.from_segments([fg_row, bg_row])
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
