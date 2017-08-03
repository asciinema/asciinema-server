defmodule Asciinema.AccountsTest do
  import Asciinema.Fixtures
  use Asciinema.DataCase
  use Bamboo.Test
  alias Asciinema.Email
  alias Asciinema.Accounts.User

  describe "send_login_email/1" do
    import Asciinema.Accounts, only: [send_login_email: 1]

    test "existing user, by email" do
      user = fixture(:user)
      assert {:ok, url} = send_login_email(user.email)
      assert_delivered_email Email.login_email(user.email, url)
    end

    test "existing user, by username" do
      user = fixture(:user)
      assert {:ok, url} = send_login_email(user.username)
      assert_delivered_email Email.login_email(user.email, url)
    end

    test "non-existing user, by email" do
      assert {:ok, url} = send_login_email("new@example.com")
      assert_delivered_email Email.signup_email("new@example.com", url)
    end

    test "non-existing user, by email, when email is invalid" do
      assert send_login_email("new@") == {:error, :email_invalid}
      assert_no_emails_delivered()
    end

    test "non-existing user, by username" do
      assert send_login_email("idontexist") == {:error, :user_not_found}
      assert_no_emails_delivered()
    end
  end

  describe "verify_signup_token/1" do
    import Asciinema.Accounts, only: [verify_signup_token: 1, signup_url: 1]

    test "invalid token" do
      assert verify_signup_token("invalid") == {:error, :token_invalid}
    end

    test "valid token" do
      token = "test@example.com" |> signup_url |> String.split("?t=") |> List.last
      assert {:ok, %User{}} = verify_signup_token(token)
      assert verify_signup_token(token) == {:error, :email_taken}
    end
  end
end
