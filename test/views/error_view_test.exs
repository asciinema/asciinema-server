defmodule Asciinema.ErrorViewTest do
  use AsciinemaWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(AsciinemaWeb.ErrorView, "404.html", []) =~
           "Not Found"
  end

  test "renders 404.json" do
    assert render_to_string(AsciinemaWeb.ErrorView, "404.json", []) ==
           "{\"error\":\"Not Found\"}"
  end

  test "render 500.html" do
    assert render_to_string(AsciinemaWeb.ErrorView, "500.html", []) ==
           "Internal Server Error"
  end

  test "render 500.json" do
    assert render_to_string(AsciinemaWeb.ErrorView, "500.json", []) ==
           "{\"error\":\"Internal Server Error\"}"
  end

  test "render any other (html)" do
    assert render_to_string(AsciinemaWeb.ErrorView, "505.html", []) ==
           "HTTP Version Not Supported"
  end

  test "render any other (json)" do
    assert render_to_string(AsciinemaWeb.ErrorView, "505.json", []) ==
           "{\"error\":\"HTTP Version Not Supported\"}"
  end
end
