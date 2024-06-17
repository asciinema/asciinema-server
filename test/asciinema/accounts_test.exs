defmodule Asciinema.AccountsTest do
  import Asciinema.Factory
  use Asciinema.DataCase
  use Oban.Testing, repo: Asciinema.Repo
  alias Asciinema.Accounts

  describe "verify_sign_up_token/1" do
    test "invalid token" do
      assert Accounts.verify_sign_up_token("invalid") == {:error, :token_invalid}
    end

    test "valid token" do
      {:ok, {:sign_up, token, _email}} = Accounts.generate_login_token("test@example.com")
      assert {:ok, "test@example.com"} = Accounts.verify_sign_up_token(token)
    end
  end

  describe "generate_login_url/3" do
    test "existing user, by email" do
      insert(:user, email: "test@example.com")

      assert {:ok, {:login, _token, "test@example.com"}} =
               Accounts.generate_login_token("test@example.com")
    end

    test "existing user, by username" do
      insert(:user, username: "test", email: "test@example.com")

      assert {:ok, {:login, _token, "test@example.com"}} = Accounts.generate_login_token("test")
    end

    test "non-existing user, by email" do
      assert {:ok, {:sign_up, _token, "foo@example.com"}} =
               Accounts.generate_login_token("foo@example.com")

      assert {:ok, {:sign_up, _token, "foo@ex.ample.com"}} =
               Accounts.generate_login_token("foo@ex.ample.com")
    end

    test "non-existing user, by email, when sign up is disabled" do
      assert Accounts.generate_login_token("foo@example.com", register: false) ==
               {:error, :user_not_found}
    end

    test "non-existing user, by email, when email is invalid" do
      assert Accounts.generate_login_token("foo@") == {:error, :email_invalid}
      assert Accounts.generate_login_token("foo@ex.ample..com") == {:error, :email_invalid}
    end

    test "non-existing user, by username" do
      assert Accounts.generate_login_token("idontexist") == {:error, :user_not_found}
    end
  end

  describe "update_user/2" do
    test "success" do
      user = insert(:user)

      assert success(user, %{email: "new@one.com"})
      assert success(user, %{email: "ANOTHER@ONE.COM"}).email == "another@one.com"
      assert success(user, %{username: "newone"})
    end

    test "validation failures" do
      user = insert(:user)

      assert_validation_error(user, %{email: "newone.com"})
      assert_validation_error(user, %{email: ""})
      assert_validation_error(user, %{username: ""})
    end

    defp success(user, attrs) do
      assert {:ok, user} = Accounts.update_user(user, attrs)

      user
    end

    defp assert_validation_error(user, attrs) do
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, attrs)
    end
  end
end
