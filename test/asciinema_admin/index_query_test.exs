defmodule AsciinemaAdmin.IndexQueryTest do
  use Asciinema.DataCase, async: true

  alias AsciinemaAdmin.IndexQuery

  test "invalid sort preserves typed sort state and blocks query execution" do
    index = IndexQuery.build(:recordings, %{"q" => "deploy", "sort" => "NOPE.desc"})

    refute index.valid?
    assert index.sort_param == "nope.desc"
    assert index.query == nil
    assert index.query_params == %{q: "deploy", sort: "nope.desc"}
    assert ["Invalid sort \"nope.desc\""] = index.errors
  end

  test "blank sort falls back to entity default" do
    index = IndexQuery.build(:streams, %{"sort" => "   "})

    assert index.valid?
    assert index.sort_param == "last-started.desc"
  end
end
