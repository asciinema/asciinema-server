defmodule AsciinemaAdmin.SavedQueriesTest do
  use Asciinema.DataCase, async: true

  alias AsciinemaAdmin.{IndexQuery, SavedQueries}

  test "creates saved query with normalized filter and prevents duplicates" do
    attrs = %{
      "entity" => "recordings",
      "name" => "Featured public",
      "filter" => "visibility:PUBLIC featured:true",
      "sort" => "views.desc"
    }

    assert {:ok, saved} = SavedQueries.create(attrs)
    assert saved.normalized_filter == "featured:yes visibility:public"
    assert saved.sort == "views.desc"

    assert {:error, changeset} =
             SavedQueries.create(%{
               attrs
               | "name" => "Other name",
                 "filter" => "featured:yes visibility:public"
             })

    assert %{normalized_filter: _} = errors_on(changeset)
  end

  test "rejects invalid filter" do
    assert {:error, changeset} =
             SavedQueries.create(%{
               "entity" => "streams",
               "name" => "Broken",
               "filter" => "live:maybe",
               "sort" => "created.desc"
             })

    assert %{filter: [_]} = errors_on(changeset)
  end

  test "rejects a missing or unknown entity without crashing" do
    for entity <- [nil, "", "bogus", "name"] do
      assert {:error, changeset} =
               SavedQueries.create(%{
                 "entity" => entity,
                 "name" => "X",
                 "filter" => "foo",
                 "sort" => "created.desc"
               })

      assert %{filter: ["Invalid saved query entity"]} = errors_on(changeset)
    end
  end

  test "renames a saved query and rejects duplicate names" do
    {:ok, a} =
      SavedQueries.create(%{
        "entity" => "recordings",
        "name" => "First",
        "filter" => "featured:yes",
        "sort" => "created.desc"
      })

    {:ok, b} =
      SavedQueries.create(%{
        "entity" => "recordings",
        "name" => "Second",
        "filter" => "visibility:public",
        "sort" => "created.desc"
      })

    assert {:ok, renamed} = SavedQueries.rename(a, "Renamed")
    assert renamed.name == "Renamed"

    assert {:error, changeset} = SavedQueries.rename(b, "Renamed")
    assert %{name: [_]} = errors_on(changeset)
  end

  test "invalid ad hoc query does not match saved query by partial normalization" do
    {:ok, saved} =
      SavedQueries.create(%{
        "entity" => "recordings",
        "name" => "Deploy",
        "filter" => "deploy",
        "sort" => "created.desc"
      })

    index = IndexQuery.build(:recordings, %{"q" => "#{saved.filter} bad:", "sort" => saved.sort})

    refute index.valid?
    assert index.active_saved_query == nil
  end
end
