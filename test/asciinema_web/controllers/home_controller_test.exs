defmodule AsciinemaWeb.HomeControllerTest do
  use AsciinemaWeb.ConnCase, async: true

  test "renders the static demo without a database recording", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)

    assert html =~ "/demo/homepage.cast"
    assert html =~ "npt:28.449"
    assert html =~ "asciinema-neo-dark"
    assert html =~ "asciinema-neo-light"
    refute html =~ "About this demo"
  end

  test "serves the bundled v3 recording", %{conn: conn} do
    body = conn |> get(~p"/demo/homepage.cast") |> response(200)
    [header | events] = String.split(body, "\n", trim: true)
    assert %{"version" => 3, "term" => %{"cols" => 72, "rows" => 18}} = Jason.decode!(header)
    assert Enum.any?(events, &match?([_, "m", _], Jason.decode!(&1)))
  end
end
