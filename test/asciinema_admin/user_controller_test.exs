defmodule AsciinemaAdmin.UserControllerTest do
  use AsciinemaAdmin.ConnCase, async: true

  alias Asciinema.{Accounts, Repo}
  alias Asciinema.Accounts.User
  alias Asciinema.Recordings.Asciicast

  describe "GET /admin/users" do
    test "renders the users table", %{conn: conn} do
      insert(:user, username: "alice")
      insert(:user, username: "bob")

      conn = get(conn, ~p"/admin/users")
      body = html_response(conn, 200)

      assert body =~ "Users"
      assert body =~ "alice"
      assert body =~ "bob"
    end

    test "filters by search query", %{conn: conn} do
      insert(:user, username: "alice")
      insert(:user, username: "bob")

      conn = get(conn, ~p"/admin/users?q=ali")
      body = html_response(conn, 200)

      assert body =~ "alice"
      refute body =~ ">bob<"
    end

    test "sorts by recording count", %{conn: conn} do
      few = insert(:user, username: "few-recordings")
      many = insert(:user, username: "many-recordings")
      insert(:asciicast, user: few)
      insert_list(2, :asciicast, user: many)

      body =
        conn
        |> get(~p"/admin/users?#{%{sort: "recordings.desc"}}")
        |> html_response(200)

      assert body =~ "many-recordings"
      assert body =~ "few-recordings"
      assert :binary.match(body, "many-recordings") < :binary.match(body, "few-recordings")
    end

    test "page links move between previous and next pages",
         %{conn: conn} do
      # Page size is 50; insert 51 to force at least one row onto page 2.
      users = insert_list(51, :user)
      # Newest insert is at the top of page 1, oldest at the bottom of page 2.
      newest_id = List.last(users).id
      oldest_id = List.first(users).id

      page1 = conn |> get(~p"/admin/users") |> html_response(200)
      assert page1 =~ "Next →"
      refute page1 =~ "← Previous"
      assert page1 =~ "Page 1 of 2"
      assert page1 =~ ~s(/admin/users/#{newest_id}")
      refute page1 =~ ~s(/admin/users/#{oldest_id}")

      page2 =
        conn
        |> get(~p"/admin/users?page=2")
        |> html_response(200)

      assert page2 =~ "← Previous"
      assert page2 =~ "Page 2 of 2"
      assert page2 =~ ~s(/admin/users/#{oldest_id}")
      refute page2 =~ ~s(/admin/users/#{newest_id}")

      page1_again =
        conn
        |> get(~p"/admin/users?page=1")
        |> html_response(200)

      assert page1_again =~ ~s(/admin/users/#{newest_id}")
      refute page1_again =~ ~s(/admin/users/#{oldest_id}")
      refute page1_again =~ "← Previous"
    end

    test "garbage page doesn't crash; falls through to the first page",
         %{conn: conn} do
      insert(:user, username: "alice")

      body =
        conn
        |> get(~p"/admin/users?page=not-a-page")
        |> html_response(200)

      assert body =~ "alice"
    end
  end

  describe "GET /admin/users/:id" do
    test "renders the user detail page", %{conn: conn} do
      user =
        insert(:user,
          username: "alice",
          timezone: "Europe/Warsaw",
          default_recording_visibility: :unlisted,
          term_theme_name: "dracula"
        )

      conn = get(conn, ~p"/admin/users/#{user.id}")
      body = html_response(conn, 200)

      assert body =~ "alice"
      # cards
      assert body =~ "Account"
      assert body =~ "Activity"
      assert body =~ "Streaming"
      assert body =~ "Visibility defaults"
      assert body =~ "Terminal defaults"
      # surfaced fields
      assert body =~ "Europe/Warsaw"
      assert body =~ "unlisted"
      # theme slug renders via its friendly display name
      assert body =~ "Dracula"
      # operational sections
      assert body =~ "Authorized CLIs"
      assert body =~ "Merge into another user"
      assert body =~ "Delete user"
    end

    test "falls back to the temporary username when no username is set", %{conn: conn} do
      user = insert(:user, username: nil, temporary_username: "temp-1234")

      body = conn |> get(~p"/admin/users/#{user.id}") |> html_response(200)

      assert body =~ "temp-1234"
      assert body =~ "temporary"
    end

    test "returns 404 for missing user", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        get(conn, ~p"/admin/users/9999999")
      end
    end
  end

  describe "GET /admin/users/new" do
    test "renders the form", %{conn: conn} do
      conn = get(conn, ~p"/admin/users/new")
      body = html_response(conn, 200)

      assert body =~ "New user"
      assert body =~ "Username"
      assert body =~ "Email"
    end
  end

  describe "POST /admin/users" do
    test "creates a user with valid params", %{conn: conn} do
      params = %{"user" => %{"username" => "newuser", "email" => "new@example.com"}}

      conn = post(conn, ~p"/admin/users", params)

      assert %User{username: "newuser"} = Accounts.find_user("newuser")
      assert redirected_to(conn) =~ "/admin/users/"
      assert flash(conn, :info) =~ "created"
    end

    test "rerenders form on validation failure", %{conn: conn} do
      params = %{"user" => %{"username" => "a", "email" => "bad"}}

      conn = post(conn, ~p"/admin/users", params)

      assert html_response(conn, 200) =~ "New user"
    end
  end

  describe "GET /admin/users/:id/edit and PUT" do
    test "renders the edit form", %{conn: conn} do
      user = insert(:user, username: "alice")

      conn = get(conn, ~p"/admin/users/#{user.id}/edit")

      assert html_response(conn, 200) =~ "Edit alice"
    end

    test "updates user on success", %{conn: conn} do
      user = insert(:user, username: "alice")

      conn =
        put(conn, ~p"/admin/users/#{user.id}", %{
          "user" => %{
            "username" => "alice",
            "email" => user.email,
            "name" => "Alice Updated"
          }
        })

      assert redirected_to(conn) == ~p"/admin/users/#{user.id}"
      assert flash(conn, :info) =~ "updated"
      assert Repo.get!(User, user.id).name == "Alice Updated"
    end

    test "grants and revokes admin", %{conn: conn} do
      user = insert(:user, username: "alice")
      attrs = %{"username" => "alice", "email" => user.email}

      put(conn, ~p"/admin/users/#{user.id}", %{"user" => Map.put(attrs, "is_admin", "true")})
      assert Repo.get!(User, user.id).is_admin

      put(conn, ~p"/admin/users/#{user.id}", %{"user" => Map.put(attrs, "is_admin", "false")})
      refute Repo.get!(User, user.id).is_admin
    end

    test "rerenders edit form on validation failure (invalid email)", %{conn: conn} do
      user = insert(:user, username: "alice")

      conn =
        put(conn, ~p"/admin/users/#{user.id}", %{
          "user" => %{"username" => "alice", "email" => "not-an-email"}
        })

      body = html_response(conn, 200)
      assert body =~ "Edit"
      assert Repo.get!(User, user.id).email != "not-an-email"
    end
  end

  describe "DELETE /admin/users/:id" do
    test "deletes the user and their content", %{conn: conn} do
      user = insert(:user)
      insert(:asciicast, user: user)

      conn = delete(conn, ~p"/admin/users/#{user.id}")

      assert redirected_to(conn) == ~p"/admin/users"
      assert flash(conn, :info) =~ "deleted"
      refute Repo.get(User, user.id)
      assert Repo.aggregate(from(a in Asciicast, where: a.user_id == ^user.id), :count) == 0
    end
  end

  describe "GET /admin/users/:id/merge" do
    test "shows confirmation page when target exists", %{conn: conn} do
      src = insert(:user, username: "alice")
      dst = insert(:user, username: "bob")

      conn = get(conn, ~p"/admin/users/#{src.id}/merge?target=#{dst.username}")
      body = html_response(conn, 200)

      assert body =~ "Confirm user merge"
      assert body =~ "alice"
      assert body =~ "bob"
    end

    test "redirects with error when target missing", %{conn: conn} do
      src = insert(:user)

      conn = get(conn, ~p"/admin/users/#{src.id}/merge?target=nosuchuser")

      assert redirected_to(conn) == ~p"/admin/users/#{src.id}"
      assert flash(conn, :error) =~ "not found"
    end

    test "redirects with error when target == source", %{conn: conn} do
      src = insert(:user, username: "alice")

      conn = get(conn, ~p"/admin/users/#{src.id}/merge?target=#{src.username}")

      assert redirected_to(conn) == ~p"/admin/users/#{src.id}"
      assert flash(conn, :error) =~ "differ"
    end
  end

  describe "POST /admin/users/:id/merge" do
    test "merges src into dst and redirects to dst", %{conn: conn} do
      src = insert(:user, username: "alice")
      dst = insert(:user, username: "bob")
      insert(:asciicast, user: src)

      conn = post(conn, ~p"/admin/users/#{src.id}/merge", %{"target" => to_string(dst.id)})

      assert redirected_to(conn) == ~p"/admin/users/#{dst.id}"
      assert flash(conn, :info) =~ "Merged"
      refute Repo.get(User, src.id)
      assert Repo.aggregate(from(a in Asciicast, where: a.user_id == ^dst.id), :count) == 1
    end
  end
end
