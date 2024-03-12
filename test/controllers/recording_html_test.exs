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
                 [["foobar", %{}]],
                 [["bazquxquux", %{}]],
                 [["alberto", %{}]],
                 [["balsam", %{}]]
               ],
               5,
               3
             ) == [
               [{"bazqu", %{}}],
               [{"alber", %{}}],
               [{"balsa", %{}}]
             ]
    end

    test "taller terminal with trailing blank lines" do
      assert thumbnail_lines(
               [
                 [["foobar", %{}]],
                 [["bazquxquux", %{}]],
                 [],
                 []
               ],
               5,
               3
             ) == [
               [{"fooba", %{}}],
               [{"bazqu", %{}}],
               []
             ]
    end

    test "shorter terminal with trailing blank lines" do
      assert thumbnail_lines(
               [
                 [["foobar", %{}]],
                 [["bazquxquux", %{}]],
                 []
               ],
               5,
               5
             ) == [
               [{"fooba", %{}}],
               [{"bazqu", %{}}],
               [],
               [],
               []
             ]
    end
  end
end
