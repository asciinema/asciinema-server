defmodule AsciinemaWeb.PngGeneratorTest do
  use ExUnit.Case, async: true

  alias Asciinema.Ecto.Type.Snapshot, as: EctoSnapshot
  alias Asciinema.Recordings.Asciicast
  alias AsciinemaWeb.PngGenerator
  alias AsciinemaWeb.PngGenerator.Error

  @bg_rgb {18, 19, 20}
  @cell_width 8.42333333 * 2
  @cell_height 14 * 1.333333 * 2
  @cell_left @cell_width
  @cell_top @cell_height / 2
  @bg_threshold 8
  @cell_bg_ratio 0.8

  test "retryable flag can be set on retryable failures" do
    assert %Error{retryable: true} = %Error{type: :busy, reason: 30_000, retryable: true}

    assert %Error{retryable: true} = %Error{
             type: :timeout,
             reason: :rsvg_convert,
             retryable: true
           }
  end

  test "retryable defaults to false" do
    assert %Error{retryable: false} = %Error{type: :generator_failed, reason: {"oops", 1}}
  end

  @tag :rsvg
  test "renders ASCII text into PNG output" do
    tmp_dir = Briefly.create!(directory: true)

    image =
      cells_asciicast(10, ["H"], 20, 8)
      |> generate_png(tmp_dir)
      |> raw_img()

    assert_cell_has_ink_at(image, 0, 0, 0.15, 0.35)
    assert_cell_has_ink_at(image, 0, 0, 0.78, 0.35)
    assert_cell_has_ink_at(image, 0, 0, 0.5, 0.47)
    assert_cell_has_background_at(image, 0, 0, 0.5, 0.1)
    assert_cell_has_background_at(image, 0, 0, 0.5, 0.9)
  end

  @tag :rsvg
  test "preserves leading and repeated spaces in PNG output" do
    tmp_dir = Briefly.create!(directory: true)
    cols = 20
    rows = 8

    one_space =
      text_asciicast(1, String.duplicate("foo bar", 2), cols, rows)
      |> generate_png(tmp_dir)
      |> raw_img()

    two_spaces =
      text_asciicast(2, String.duplicate("foo  bar", 2), cols, rows)
      |> generate_png(tmp_dir)
      |> raw_img()

    no_leading_spaces =
      text_asciicast(3, String.duplicate("foo", 4), cols, rows)
      |> generate_png(tmp_dir)
      |> raw_img()

    leading_spaces =
      text_asciicast(4, String.duplicate("  foo", 4), cols, rows)
      |> generate_png(tmp_dir)
      |> raw_img()

    refute cell_mostly_background?(one_space, 4, 0)
    assert cell_mostly_background?(two_spaces, 4, 0)

    refute cell_mostly_background?(no_leading_spaces, 0, 0)
    assert cell_mostly_background?(leading_spaces, 0, 0)
    assert cell_mostly_background?(leading_spaces, 1, 0)
  end

  defp generate_png(asciicast, tmp_dir), do: PngGenerator.generate(asciicast, tmp_dir)

  defp cells_asciicast(id, cells, cols, rows, fg \\ "#ff5500") do
    %Asciicast{
      id: id,
      term_cols: cols,
      term_rows: rows,
      term_theme_name: "asciinema",
      snapshot:
        snapshot([
          Enum.map(cells, &[&1, text_attrs(fg), 1]) ++ blank_cells(cols - length(cells))
          | List.duplicate(blank_cells(cols), rows - 1)
        ])
    }
  end

  defp text_asciicast(id, text, cols, rows) do
    colored_text_asciicast(id, text, nil, cols, rows)
  end

  defp colored_text_asciicast(id, text, fg, cols, rows) do
    %Asciicast{
      id: id,
      term_cols: cols,
      term_rows: rows,
      term_theme_name: "asciinema",
      snapshot:
        snapshot([
          [[text, text_attrs(fg), 1]],
          [[text, text_attrs(fg), 1]],
          [[text, text_attrs(fg), 1]]
          | List.duplicate(blank_cells(cols), rows - 3)
        ])
    }
  end

  defp blank_cells(count) do
    List.duplicate([" ", %{}, 1], count)
  end

  defp text_attrs(nil), do: %{}
  defp text_attrs(fg), do: %{"fg" => fg}

  defp assert_cell_has_ink_at(image, col, row, x_ratio, y_ratio) do
    refute image |> cell_pixel(col, row, x_ratio, y_ratio) |> close_to?(@bg_rgb, @bg_threshold)
  end

  defp assert_cell_has_background_at(image, col, row, x_ratio, y_ratio) do
    assert image |> cell_pixel(col, row, x_ratio, y_ratio) |> close_to?(@bg_rgb, @bg_threshold)
  end

  defp cell_mostly_background?({{width, _height}, pixels}, col, row) do
    {x_range, y_range} = cell_inner_ranges(col, row)

    total =
      Enum.count(x_range) * Enum.count(y_range)

    matches =
      for x <- x_range, y <- y_range, reduce: 0 do
        count ->
          if pixels |> pixel_at(width, x, y) |> close_to?(@bg_rgb, @bg_threshold) do
            count + 1
          else
            count
          end
      end

    matches / total >= @cell_bg_ratio
  end

  defp png_dimensions(png_path) do
    {output, 0} = System.cmd("magick", ["identify", "-format", "%w %h", png_path])
    [width, height] = String.split(output)

    {String.to_integer(width), String.to_integer(height)}
  end

  defp raw_img(png_path) do
    dimensions = png_dimensions(png_path)
    {rgb, 0} = System.cmd("magick", [png_path, "-alpha", "off", "rgb:-"])

    {dimensions, rgb}
  end

  defp cell_pixel({{width, _height}, pixels}, col, row, x_ratio, y_ratio) do
    x = round(@cell_left + col * @cell_width + x_ratio * (@cell_width - 1))
    y = round(@cell_top + row * @cell_height + y_ratio * (@cell_height - 1))

    pixel_at(pixels, width, x, y)
  end

  defp pixel_at(pixels, width, x, y) do
    offset = (y * width + x) * 3

    <<_::binary-size(offset), r, g, b, _::binary>> = pixels
    {r, g, b}
  end

  defp cell_inner_ranges(col, row) do
    x0 = @cell_left + col * @cell_width
    y0 = @cell_top + row * @cell_height

    x_range =
      ceil(x0 + @cell_width * 0.2)..floor(x0 + @cell_width * 0.8)

    y_range =
      ceil(y0 + @cell_height * 0.2)..floor(y0 + @cell_height * 0.8)

    {x_range, y_range}
  end

  defp close_to?({r1, g1, b1}, {r2, g2, b2}, threshold) do
    abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2) <= threshold
  end

  defp snapshot(lines) do
    {:ok, snapshot} = EctoSnapshot.cast({lines, nil})

    snapshot
  end
end
