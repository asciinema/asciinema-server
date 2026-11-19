defmodule AsciinemaWeb.NeoThemeTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory

  alias Asciinema.{Accounts, Media, Recordings, Streaming, Themes}
  alias AsciinemaWeb.{PngGenerator, RecordingSVG}

  test "inherits Neo Dark, while explicit Classic and account preferences retain their meaning" do
    recording = build(:asciicast)
    assert Media.theme(recording).name == "asciinema Neo Dark"
    account = %{recording.user | term_theme_name: "asciinema-neo-light"}
    assert Media.theme(%{recording | user: account}).bg == "#f7f7f7"
    classic = %{recording | user: account, term_theme_name: "asciinema"}
    assert Media.theme(classic).name == "asciinema Classic"
    assert Media.theme(classic).bg == "#121314"
  end

  test "both Neo options can be saved at each preference level" do
    for name <- ["asciinema-neo-dark", "asciinema-neo-light"] do
      user = insert(:user)

      assert {:ok, %{term_theme_name: ^name}} =
               Accounts.update_user(user, %{term_theme_name: name})

      recording = insert(:asciicast, user: user)

      assert {:ok, %{term_theme_name: ^name}} =
               Recordings.update_asciicast(recording, %{term_theme_name: name})

      stream = insert(:stream, user: user)

      assert {:ok, %{term_theme_name: ^name}} =
               Streaming.update_stream(stream, %{term_theme_name: name})
    end
  end

  test "theme overrides supply the requested CSS on pages and iframes", %{conn: conn} do
    recording = insert(:asciicast, term_theme_name: "asciinema")
    stream = insert(:stream, term_theme_name: "asciinema")

    for path <- [
          ~p"/a/#{recording}",
          ~p"/a/#{recording}/iframe",
          ~p"/s/#{stream}",
          ~p"/s/#{stream}/iframe"
        ],
        name <- ["asciinema-neo-light", "asciinema-neo-dark"] do
      html = conn |> get(path <> "?theme=" <> name) |> html_response(200)
      assert html =~ ~s("theme":"#{name}")
      assert html =~ "--term-color-background: #{Themes.named_theme(name).bg};"
    end
  end

  test "stream CSS uses the named fallback even when a captured palette is available" do
    stream =
      build(:stream,
        term_theme_prefer_original: true,
        term_theme_fg: "#ffffff",
        term_theme_bg: "#000000",
        term_theme_palette: Enum.map_join(0..15, ":", fn _ -> "#123456" end)
      )

    assert Media.theme(stream).bg == "#000000"
    assert Media.player_theme(stream).bg == "#191c22"
    assert Media.player_theme(stream, "auto/asciinema-neo-light").bg == "#f7f7f7"
    assert Media.player_theme(stream, "original").bg == "#000000"
  end

  test "image keys follow effective colours, including inherited account changes" do
    recording = build(:asciicast, snapshot: Asciinema.Recordings.Snapshot.new([]))
    light = %{recording | user: %{recording.user | term_theme_name: "asciinema-neo-light"}}

    for key <- [&RecordingSVG.svg_cache_key/1, &PngGenerator.png_cache_key/1] do
      refute key.(recording) == key.(light)

      assert key.(%{recording | term_theme_name: "asciinema"}) ==
               key.(%{light | term_theme_name: "asciinema"})
    end
  end
end
