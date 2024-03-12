defmodule Asciinema.RecordingHTMLTest do
  use AsciinemaWeb.ConnCase, async: true
  alias AsciinemaWeb.RecordingHTML
  alias Asciinema.Recordings.Asciicast

  def thumbnail_lines(snapshot, w, h) do
    asciicast = %Asciicast{snapshot: snapshot}
    RecordingHTML.thumbnail_lines(asciicast, w, h)
  end

  describe "thumbnail_lines/3" do
    test "blank taller terminal" do
      assert thumbnail_lines(
               [
                 [],
                 []
               ],
               5,
               1
             ) == [
               []
             ]
    end

    test "blank shorter terminal" do
      assert thumbnail_lines(
               [
                 []
               ],
               5,
               2
             ) == [
               [],
               []
             ]
    end

    test "taller terminal" do
      assert thumbnail_lines(
               [
                 [["foobar", %{}, 1]],
                 [["bazquxquux", %{}, 1]],
                 [["alberto", %{}, 1]],
                 [["balsam", %{}, 1]]
               ],
               5,
               3
             ) == [
               [{"bazqu", %{}, 1}],
               [{"alber", %{}, 1}],
               [{"balsa", %{}, 1}]
             ]
    end

    test "taller terminal with trailing blank lines" do
      assert thumbnail_lines(
               [
                 [["foobar", %{}, 1]],
                 [["bazquxquux", %{}, 1]],
                 [],
                 []
               ],
               5,
               3
             ) == [
               [{"fooba", %{}, 1}],
               [{"bazqu", %{}, 1}],
               []
             ]
    end

    test "shorter terminal with trailing blank lines" do
      assert thumbnail_lines(
               [
                 [["foobar", %{}, 1]],
                 [["bazquxquux", %{}, 1]],
                 []
               ],
               5,
               5
             ) == [
               [{"fooba", %{}, 1}],
               [{"bazqu", %{}, 1}],
               [],
               [],
               []
             ]
    end
  end
end
