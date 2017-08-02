defmodule Asciinema.AccountsTest do
  import Asciinema.Fixtures
  use Asciinema.DataCase
  use Bamboo.Test
  alias Asciinema.Email

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
end
