defmodule Asciinema.AccountsTest do
  import Asciinema.Factory
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo
  alias Asciinema.Accounts

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
  end

  describe "confirm_sign_up/3" do
    test "succeeds when token valid and email not taken" do
      {:ok, {:sign_up, token, _email}} = Accounts.initiate_login("test@example.com")

      assert {:ok, %{username: "signupacct"}} = Accounts.confirm_sign_up(token, "signupacct")
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

  describe "list_users/1" do
    test "returns all users on one page by default" do
      base = length(Accounts.list_users().entries)
      insert_list(3, :user)

      assert length(Accounts.list_users().entries) == base + 3
    end

    test "respects the :page_size option" do
      insert_list(5, :user)

      assert length(Accounts.list_users(page_size: 2).entries) == 2
    end

    test "orders by inserted_at desc, id desc by default" do
      first = insert(:user)
      second = insert(:user)
      third = insert(:user)

      ids = Accounts.list_users(page_size: 3).entries |> Enum.map(& &1.id)

      assert ids == [third.id, second.id, first.id]
    end

    test "search by id" do
      user = insert(:user)
      _other = insert(:user)

      assert [%{id: id}] = Accounts.list_users(search: to_string(user.id)).entries
      assert id == user.id
    end

    test "search by username (case-insensitive substring)" do
      user = insert(:user, username: "AliceCool")
      _other = insert(:user, username: "bob")

      assert [%{id: id}] = Accounts.list_users(search: "ali").entries
      assert id == user.id
    end

    test "search by email (case-insensitive substring)" do
      user = insert(:user, email: "alice@example.com")
      _other = insert(:user, email: "bob@example.com")

      assert [%{id: id}] = Accounts.list_users(search: "ALICE@").entries
      assert id == user.id
    end

    test "search by unknown value returns empty" do
      insert(:user, username: "alice")

      assert Accounts.list_users(search: "no-such-user").entries == []
    end

    test "sort by :last_login_at desc with NULLs last" do
      a = insert(:user, last_login_at: ~U[2025-01-01 00:00:00Z])
      b = insert(:user, last_login_at: ~U[2025-02-01 00:00:00Z])
      c = insert(:user, last_login_at: nil)

      ids =
        Accounts.list_users(sort_by: :last_login_at, sort_dir: :desc).entries
        |> Enum.map(& &1.id)
        |> Enum.filter(&(&1 in [a.id, b.id, c.id]))

      assert ids == [b.id, a.id, c.id]
    end

    test "offset pagination returns subsequent pages" do
      insert_list(3, :user)

      all = Accounts.list_users(page_size: 100).entries |> Enum.map(& &1.id)
      page1 = Accounts.list_users(page: 1, page_size: 2).entries |> Enum.map(& &1.id)
      page2 = Accounts.list_users(page: 2, page_size: 2).entries |> Enum.map(& &1.id)

      assert page1 == Enum.take(all, 2)
      assert page2 == all |> Enum.drop(2) |> Enum.take(2)
    end
  end
end
