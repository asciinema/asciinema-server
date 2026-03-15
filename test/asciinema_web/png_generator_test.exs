defmodule AsciinemaWeb.PngGeneratorTest do
  use ExUnit.Case, async: true

  alias Asciinema.Ecto.Type.Snapshot, as: EctoSnapshot
  alias Asciinema.Recordings.Asciicast
  alias AsciinemaWeb.PngGenerator
  alias AsciinemaWeb.PngGenerator.Error

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
      colored_text_asciicast(10, "HHHHHHHH", "#ff5500", 20, 8)
      |> generate_png(tmp_dir)
      |> raw_img()

    for {x, y} <- [{19, 28}, {36, 28}, {63, 28}, {80, 28}] do
      assert pixel_close_to?(image, x, y, {255, 85, 0}, 80)
    end
  end

  defp generate_png(asciicast, tmp_dir) do
    asciicast
    |> PngGenerator.generate(tmp_dir)
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

  defp pixel_close_to?({{width, _height}, pixels}, x, y, expected_rgb, threshold) do
    pixels
    |> pixel_at(width, x, y)
    |> close_to?(expected_rgb, threshold)
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

  defp pixel_at(pixels, width, x, y) do
    offset = (y * width + x) * 3

    <<_::binary-size(offset), r, g, b, _::binary>> = pixels
    {r, g, b}
  end

  defp close_to?({r1, g1, b1}, {r2, g2, b2}, threshold) do
    abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2) <= threshold
  end

  defp snapshot(lines) do
    {:ok, snapshot} = EctoSnapshot.cast({lines, nil})
    snapshot
  end
end
