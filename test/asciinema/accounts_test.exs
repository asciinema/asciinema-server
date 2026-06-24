defmodule Asciinema.AccountsTest do
  import Asciinema.Factory
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo
  alias Asciinema.Accounts
  alias Asciinema.Accounts.Query

  describe "create_user/1" do
    test "succeeds for valid attrs" do
      assert {:ok, _} =
               Accounts.create_user(%{email: "test@example.com", username: "test"})
    end

    test "fails for invalid attrs" do
      assert {:error, %Ecto.Changeset{}} =
               Accounts.create_user(%{email: "test@example.com", username: "a"})
    end

    test "fails without username" do
      assert {:error, %Ecto.Changeset{}} =
               Accounts.create_user(%{email: "test@example.com"})
    end

    test "makes the first registered user an admin" do
      assert {:ok, %{is_admin: true}} =
               Accounts.create_user(%{email: "first@example.com", username: "first"})
    end

    test "does not make subsequent registered users admins" do
      insert(:user, email: "existing@example.com")

      assert {:ok, user} =
               Accounts.create_user(%{email: "second@example.com", username: "second"})

      refute user.is_admin
    end

    test "ignores temporary (email-less) users when bootstrapping the first admin" do
      insert(:temporary_user)

      assert {:ok, %{is_admin: true}} =
               Accounts.create_user(%{email: "first@example.com", username: "first"})
    end
  end

  describe "find_user_by_profile_id/1" do
    test "finds a user by username, case-insensitively" do
      user = insert(:user, username: "Nick")

      assert %{id: id} = Accounts.find_user_by_profile_id("nick")
      assert id == user.id
    end

    test "returns nil for an invalid UTF-8 username" do
      # A path like /~ник<lone surrogate> decodes to a binary that isn't valid
      # UTF-8; it can never match a username and must not reach the database.
      invalid = <<0xD0, 0xBD, 0xD0, 0xB8, 0xD0, 0xBA, 0xED, 0xB3, 0x90>>
      refute String.valid?(invalid)

      assert Accounts.find_user_by_profile_id(invalid) == nil
    end
  end

  describe "confirm_sign_up/3" do
    test "succeeds when token valid and email not taken" do
      {:ok, {:sign_up, token, _email}} = Accounts.initiate_login("test@example.com")

      assert {:ok, %{username: "signupacct"}} = Accounts.confirm_sign_up(token, "signupacct")
    end

    test "makes the first user to sign up an admin" do
      {:ok, {:sign_up, token, _email}} = Accounts.initiate_login("first@example.com")

      assert {:ok, %{is_admin: true}} = Accounts.confirm_sign_up(token, "firstacct")
    end

    test "fails when invalid token" do
      assert Accounts.confirm_sign_up("invalid", "signupacct") == {:error, :token_invalid}
    end

    test "fails when email address taken" do
      {:ok, {:sign_up, token, _email}} = Accounts.initiate_login("test@example.com")
      insert(:user, email: "test@example.com")

      assert Accounts.confirm_sign_up(token, "signupacct") == {:error, :email_taken}
    end

    test "fails when username invalid" do
      {:ok, {:sign_up, token, _email}} = Accounts.initiate_login("test@example.com")

      assert {:error, %Ecto.Changeset{}} = Accounts.confirm_sign_up(token, "---")
      assert Accounts.find_user("test@example.com") == nil
    end

    test "fails when username blank" do
      {:ok, {:sign_up, token, _email}} = Accounts.initiate_login("test@example.com")

      assert {:error, %Ecto.Changeset{}} = Accounts.confirm_sign_up(token, "")
      assert Accounts.find_user("test@example.com") == nil
    end
  end

  describe "initiate_login/1" do
    test "existing user, by email" do
      insert(:user, email: "test@example.com")

      assert {:ok, {:login, _token, "test@example.com"}} =
               Accounts.initiate_login("test@example.com")
    end

    test "existing user, by username" do
      insert(:user, username: "test", email: "test@example.com")

      assert {:ok, {:login, _token, "test@example.com"}} = Accounts.initiate_login("test")
    end

    test "non-existing user, by email" do
      assert {:ok, {:sign_up, _token, "foo@example.com"}} =
               Accounts.initiate_login("foo@example.com")

      assert {:ok, {:sign_up, _token, "foo@ex.ample.com"}} =
               Accounts.initiate_login("foo@ex.ample.com")
    end

    test "non-existing user, by email, when sign up is disabled" do
      assert Accounts.initiate_login("foo@example.com", register: false) ==
               {:error, :user_not_found}
    end

    test "non-existing user, by email, when email is invalid" do
      assert Accounts.initiate_login("foo@") == {:error, :email_invalid}
      assert Accounts.initiate_login("foo@ex.ample..com") == {:error, :email_invalid}
    end

    test "non-existing user, by username" do
      assert Accounts.initiate_login("idontexist") == {:error, :user_not_found}
    end
  end

  describe "update_user/2" do
    test "success" do
      user = insert(:user)

      assert success(user, %{username: "newone"}).username == "newone"
      assert success(user, %{name: "New One"}).name == "New One"
    end

    test "validation failures" do
      user = insert(:user)

      assert_validation_error(user, %{username: ""})
      assert_validation_error(user, %{term_theme_name: "lol"})
    end

    defp success(user, attrs) do
      assert {:ok, user} = Accounts.update_user(user, attrs)

      user
    end

    defp assert_validation_error(user, attrs) do
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, attrs)
    end
  end

  describe "list_clis/1" do
    test "returns the user's CLIs newest first" do
      user = insert(:user)
      older = insert(:cli, user: user, inserted_at: ~U[2026-01-01 00:00:00Z])
      newer = insert(:cli, user: user, inserted_at: ~U[2026-06-01 00:00:00Z])

      assert Enum.map(Accounts.list_clis(user), & &1.id) == [newer.id, older.id]
    end
  end

  describe "initiate_email_change/2" do
    test "succeeds when email not taken" do
      user = insert(:user, email: "test@example.com")

      assert {:ok, {:pending, {"new@example.com", _token}}} =
               Accounts.initiate_email_change(user, "NEW@example.com")
    end

    test "fails when email address taken" do
      user = insert(:user, email: "test@example.com")
      insert(:user, email: "new@example.com")

      assert Accounts.initiate_email_change(user, "NEW@example.com") == {:error, :taken}
    end
  end

  describe "confirm_email_change/2" do
    test "succeeds when token valid and email not taken" do
      user = insert(:user, email: "test@example.com")
      token = Accounts.generate_email_change_token(user, "new@example.com")

      assert {:ok, %{email: "new@example.com"}} = Accounts.confirm_email_change(user, token)
    end

    test "fails when invalid token" do
      user = insert(:user)

      assert Accounts.confirm_email_change(user, "invalid") == {:error, :invalid_token}
    end

    test "fails when email address taken" do
      user = insert(:user, email: "test@example.com")
      insert(:user, email: "new@example.com")
      token = Accounts.generate_email_change_token(user, "new@example.com")

      assert Accounts.confirm_email_change(user, token) == {:error, :email_taken}
    end

    test "fails when account email has changed since token generation" do
      user = insert(:user, email: "old@example.com")
      token = Accounts.generate_email_change_token(user, "new@example.com")
      other_token = Accounts.generate_email_change_token(user, "other@example.com")
      {:ok, user} = Accounts.confirm_email_change(user, other_token)

      assert Accounts.confirm_email_change(user, token) == {:error, :email_changed}
    end
  end

  describe "verify_email_change/2" do
    test "succeeds when token valid and generated for user" do
      user = insert(:user)
      token = Accounts.generate_email_change_token(user, "new@example.com")

      assert Accounts.verify_email_change(user, token) == {:ok, "new@example.com"}
    end

    test "fails when invalid token" do
      user = insert(:user)

      assert Accounts.verify_email_change(user, "invalid") == {:error, :invalid_token}
    end

    test "fails when token was generated for another user" do
      user = insert(:user)
      other_user = insert(:user)
      token = Accounts.generate_email_change_token(other_user, "new@example.com")

      assert Accounts.verify_email_change(user, token) == {:error, :user_mismatch}
    end

    test "fails when account email has changed since token generation" do
      user = insert(:user, email: "old@example.com")
      token = Accounts.generate_email_change_token(user, "new@example.com")
      other_token = Accounts.generate_email_change_token(user, "other@example.com")
      {:ok, user} = Accounts.confirm_email_change(user, other_token)

      assert Accounts.verify_email_change(user, token) == {:error, :email_changed}
    end
  end

  describe "user query API" do
    test "supports admin and system scopes" do
      user = insert(:user)

      for scope <- [:admin, :system] do
        ids =
          %Query{scope: scope, filters: [{:id, user.id}]}
          |> Accounts.list(10)
          |> Enum.map(& &1.id)

        assert ids == [user.id]
      end
    end

    test "returns all users by default" do
      base =
        %Query{scope: :admin, sort: {:created, :desc}}
        |> Accounts.list(50)
        |> length()

      insert_list(3, :user)

      count =
        %Query{scope: :admin, sort: {:created, :desc}}
        |> Accounts.list(50)
        |> length()

      assert count == base + 3
    end

    test "paginates users" do
      insert_list(5, :user)

      page =
        %Query{scope: :admin, sort: {:created, :desc}}
        |> Accounts.paginate(1, 2)

      assert length(page.entries) == 2
      assert page.page_number == 1
      assert page.page_size == 2
      assert page.total_entries >= 5
    end

    test "orders by inserted_at desc, id desc by default" do
      first = insert(:user)
      second = insert(:user)
      third = insert(:user)

      ids =
        %Query{scope: :admin, sort: {:created, :desc}}
        |> Accounts.list(3)
        |> Enum.map(& &1.id)

      assert ids == [third.id, second.id, first.id]
    end

    test "filters by id" do
      user = insert(:user)
      _other = insert(:user)

      assert [%{id: id}] =
               %Query{scope: :admin, filters: [{:id, user.id}], sort: {:created, :desc}}
               |> Accounts.list(10)

      assert id == user.id
    end

    test "searches individual username, email, and name fields" do
      user =
        insert(:user,
          username: "AlphaNeedle",
          email: "beta-needle@example.com",
          name: "Gamma Needle"
        )

      insert(:user, username: "unrelated", email: "other@example.com", name: "Other")

      for filter <- [
            {:username, {:search, "ALPHA"}},
            {:email, {:search, "BETA-NEEDLE"}},
            {:name, {:search, "GAMMA"}}
          ] do
        assert [%{id: id}] =
                 %Query{scope: :system, filters: [filter]}
                 |> Accounts.list(10)

        assert id == user.id
      end
    end

    test "filters by account dates and recording and stream counts" do
      low =
        insert(:user,
          username: "query-coverage-low",
          inserted_at: ~U[2025-01-01 00:00:00Z],
          last_login_at: ~U[2025-01-02 00:00:00Z]
        )

      high =
        insert(:user,
          username: "query-coverage-high",
          is_admin: true,
          inserted_at: ~U[2025-02-01 00:00:00Z],
          last_login_at: ~U[2025-02-02 00:00:00Z]
        )

      insert(:asciicast, user: low)
      insert(:asciicast, user: high, visibility: :private)
      insert(:asciicast, user: high, archived_at: ~U[2025-03-01 00:00:00Z])
      insert(:stream, user: low)
      insert_list(2, :stream, user: high)

      assert_id = fn filter, expected ->
        assert [%{id: id}] =
                 %Query{
                   scope: :system,
                   filters: [{:username, {:search, "query-coverage-"}}, filter]
                 }
                 |> Accounts.list(10)

        assert id == expected.id
      end

      assert_id.({:created_at, {:gte, ~U[2025-01-15 00:00:00Z]}}, high)
      assert_id.({:last_login_at, {:lt, ~U[2025-01-15 00:00:00Z]}}, low)
      assert_id.({:recording_count, {:gte, 2}}, high)
      assert_id.({:stream_count, {:between, 2, 2}}, high)
      assert_id.({:admin, true}, high)
      assert_id.({:admin, false}, low)
    end

    test "filters registered (has email) vs unregistered users" do
      registered = insert(:user)
      temporary = insert(:temporary_user)

      ids = fn filter ->
        %Query{scope: :admin, filters: [filter]} |> Accounts.list(100) |> Enum.map(& &1.id)
      end

      registered_ids = ids.({:registered, true})
      temporary_ids = ids.({:registered, false})

      assert registered.id in registered_ids
      refute temporary.id in registered_ids

      assert temporary.id in temporary_ids
      refute registered.id in temporary_ids
    end

    test "paginate with_counts returns per-user counts" do
      user = insert(:user)
      insert_list(3, :asciicast, user: user)
      insert(:stream, user: user)

      handler_id = "with-counts-sql-#{System.unique_integer()}"
      parent = self()

      :telemetry.attach(
        handler_id,
        [:asciinema, :repo, :query],
        fn _event, _measurements, %{query: sql}, _config ->
          # queries emit in the calling process; ignore concurrent tests' traffic
          if self() == parent and String.contains?(sql, "username") do
            send(parent, {:entries_sql, sql})
          end
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      page =
        Accounts.paginate(%Query{scope: :system, filters: [{:id, user.id}]}, 1, 10,
          with_counts: true
        )

      assert [%{recording_count: 3, stream_count: 1}] = page.entries
      # without count filters, counts come from correlated subqueries
      assert_receive {:entries_sql, sql}
      assert sql =~ "(SELECT count(*)"
      refute sql =~ "GROUP BY"

      # with a count filter present, the display counts reuse the aggregate join
      page =
        Accounts.paginate(
          %Query{scope: :system, filters: [{:id, user.id}, {:recording_count, {:gte, 1}}]},
          1,
          10,
          with_counts: true
        )

      assert [%{recording_count: 3, stream_count: 1}] = page.entries
      assert_receive {:entries_sql, sql}
      assert sql =~ "GROUP BY"
      refute sql =~ "(SELECT count(*)"
    end

    test "search by username (case-insensitive substring)" do
      user = insert(:user, username: "AliceCool")
      _other = insert(:user, username: "bob")

      assert [%{id: id}] =
               %Query{
                 scope: :admin,
                 filters: [{:identity, {:search, "ali"}}],
                 sort: {:created, :desc}
               }
               |> Accounts.list(10)

      assert id == user.id
    end

    test "search by email (case-insensitive substring)" do
      user = insert(:user, email: "alice@example.com")
      _other = insert(:user, email: "bob@example.com")

      assert [%{id: id}] =
               %Query{
                 scope: :admin,
                 filters: [{:identity, {:search, "ALICE@"}}],
                 sort: {:created, :desc}
               }
               |> Accounts.list(10)

      assert id == user.id
    end

    test "search by unknown value returns empty" do
      insert(:user, username: "alice")

      results =
        %Query{
          scope: :admin,
          filters: [{:identity, {:search, "no-such-user"}}],
          sort: {:created, :desc}
        }
        |> Accounts.list(10)

      assert results == []
    end

    test "identity search treats LIKE wildcards literally" do
      # "a_c" must match the literal underscore, not "_" as a single-char wildcard
      literal = insert(:user, username: "a_c")
      _decoy = insert(:user, username: "axc")

      ids =
        %Query{scope: :admin, filters: [{:identity, {:search, "a_c"}}], sort: {:created, :desc}}
        |> Accounts.list(10)
        |> Enum.map(& &1.id)

      assert ids == [literal.id]
    end

    test "sorts by last login desc with NULLs last" do
      a = insert(:user, last_login_at: ~U[2025-01-01 00:00:00Z])
      b = insert(:user, last_login_at: ~U[2025-02-01 00:00:00Z])
      c = insert(:user, last_login_at: nil)

      ids =
        %Query{scope: :admin, sort: {:last_login, :desc}}
        |> Accounts.list(50)
        |> Enum.map(& &1.id)
        |> Enum.filter(&(&1 in [a.id, b.id, c.id]))

      assert ids == [b.id, a.id, c.id]
    end

    test "offset page 2 returns rows after page 1" do
      first = insert(:user)
      second = insert(:user)
      third = insert(:user)

      page =
        %Query{scope: :admin, sort: {:created, :desc}}
        |> Accounts.paginate(2, 2)

      ids = Enum.map(page.entries, & &1.id)
      assert first.id in ids
      refute second.id in ids
      refute third.id in ids
    end
  end

  describe "signups_by_day/1" do
    test "returns exactly N entries" do
      assert length(Accounts.signups_by_day(7)) == 7
    end

    test "each entry is a {date, count} pair" do
      for {date, count} <- Accounts.signups_by_day(3) do
        assert %Date{} = date
        assert is_integer(count) and count >= 0
      end
    end

    test "is ordered oldest first, today last" do
      result = Accounts.signups_by_day(5)
      dates = Enum.map(result, fn {d, _} -> d end)
      assert dates == Enum.sort(dates, Date)
      assert List.last(dates) == Date.utc_today()
    end

    test "buckets users into today" do
      base = Accounts.signups_by_day(3) |> List.last() |> elem(1)
      insert_list(2, :user)
      [{_today_date, today_count}] = Enum.take(Accounts.signups_by_day(3), -1)
      assert today_count == base + 2
    end
  end
end
