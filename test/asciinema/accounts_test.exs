defmodule Asciinema.AccountsTest do
  import Asciinema.Factory
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo
  alias Asciinema.Accounts

  describe "create_user/2" do
    test "succeeds for valid attrs" do
      assert {:ok, _} =
               Accounts.create_user(%{email: "test@example.com", username: "test"}, :user)
    end

    test "fails for invalid attrs" do
      assert {:error, %Ecto.Changeset{}} =
               Accounts.create_user(%{email: "test@example.com", username: "a"}, :user)
    end
  end

  describe "confirm_sign_up/1" do
    test "succeeds when token valid and email not taken" do
      {:ok, {:sign_up, token, _email}} = Accounts.initiate_login("test@example.com")

      assert {:ok, _} = Accounts.confirm_sign_up(token)
    end

    test "fails when invalid token" do
      assert Accounts.confirm_sign_up("invalid") == {:error, :token_invalid}
    end

    test "fails when email address taken" do
      {:ok, {:sign_up, token, _email}} = Accounts.initiate_login("test@example.com")
      insert(:user, email: "test@example.com")

      assert Accounts.confirm_sign_up(token) == {:error, :email_taken}
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
  end
end
