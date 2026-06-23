defmodule AsciinemaWeb.LiveStreamCardLiveTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  alias AsciinemaWeb.LiveStreamCardLive

  describe "render/1" do
    test "renders nothing when the stream no longer exists" do
      html = rendered_to_string(LiveStreamCardLive.render(%{stream: nil}))

      assert html == ""
    end
  end
end
