defmodule Asciinema.AccountsTest do
  import Asciinema.Fixtures
  use Asciinema.DataCase
  use Oban.Testing, repo: Asciinema.Repo
  alias Asciinema.Accounts

  describe "verify_signup_token/1" do
    test "invalid token" do
      assert Accounts.verify_signup_token("invalid") == {:error, :token_invalid}
    end

    test "valid token" do
      token = Accounts.signup_token("test@example.com")
      assert {:ok, "test@example.com"} = Accounts.verify_signup_token(token)
    end
  end

  describe "generate_login_url/3" do
    defmodule Routes do
      def signup_url(_), do: "http://signup"
      def login_url(_), do: "http://login"
    end

    test "existing user, by email" do
      user = fixture(:user)

      assert Accounts.generate_login_url(user.email, true, Routes) ==
               {:ok, {:login, "http://login", user.email}}
    end

    test "existing user, by username" do
      user = fixture(:user)

      assert Accounts.generate_login_url(user.username, true, Routes) ==
               {:ok, {:login, "http://login", user.email}}
    end

    test "non-existing user, by email" do
      assert Accounts.generate_login_url("new@example.com", true, Routes) ==
               {:ok, {:signup, "http://signup", "new@example.com"}}
    end

    test "non-existing user, by email, when sign up is disabled" do
      assert Accounts.generate_login_url("new@example.com", false, Routes) ==
               {:error, :user_not_found}
    end

    test "non-existing user, by email, when email is invalid" do
      assert Accounts.generate_login_url("new@", true, Routes) == {:error, :email_invalid}
    end

    test "non-existing user, by username" do
      assert Accounts.generate_login_url("idontexist", true, Routes) == {:error, :user_not_found}
    end
  end

  describe "update_user/2" do
    setup do
      %{user: fixture(:user)}
    end

    def assert_success(user, attrs) do
      assert {:ok, _} = Accounts.update_user(user, attrs)
    end

    test "success", %{user: user} do
      assert_success(user, %{email: "new@one.com"})
      assert_success(user, %{username: "newone"})
    end

    def assert_validation_error(user, attrs) do
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, attrs)
    end

    test "validation failures", %{user: user} do
      assert_validation_error(user, %{email: "newone.com"})
      assert_validation_error(user, %{email: ""})
      assert_validation_error(user, %{username: ""})
    end
  end
end
