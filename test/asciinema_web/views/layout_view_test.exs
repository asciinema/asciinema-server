defmodule AsciinemaWeb.LayoutViewTest do
  use ExUnit.Case, async: true

  alias AsciinemaWeb.LayoutView

  describe "color_scheme/1" do
    test "allows both schemes when there's no logged in user" do
      assert LayoutView.color_scheme(%{assigns: %{current_user: nil}}) == "dark light"
    end

    test "follows the user's preference" do
      for {scheme, expected} <- [auto: "dark light", light: "light", dark: "dark"] do
        conn = %{assigns: %{current_user: %{ui_color_scheme: scheme}}}

        assert LayoutView.color_scheme(conn) == expected
      end
    end
  end
end
