defmodule AsciinemaWeb.Features.StaticPagesTest do
  use AsciinemaWeb.FeatureCase, async: true

  test "about page", %{conn: conn} do
    conn
    |> visit("/about")
    |> assert_has("h1")
  end
end
