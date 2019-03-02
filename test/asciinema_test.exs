defmodule AsciinemaTest do
  use Asciinema.DataCase
  use Bamboo.Test
  alias Asciinema.Emails.Email

  describe "send_login_email/1" do
    import Asciinema, only: [send_login_email: 3]

    defp signup_url(_), do: "http://signup"
    defp login_url(_), do: "http://login"

    test "existing user, by email" do
      user = fixture(:user)

      assert send_login_email(user.email, &signup_url/1, &login_url/1) == :ok

      assert_delivered_email Email.login_email(user.email, "http://login")
    end

    test "existing user, by username" do
      user = fixture(:user)

      assert send_login_email(user.username, &signup_url/1, &login_url/1) == :ok

      assert_delivered_email Email.login_email(user.email, "http://login")
    end

    test "non-existing user, by email" do
      assert send_login_email("new@example.com", &signup_url/1, &login_url/1) == :ok

      assert_delivered_email Email.signup_email("new@example.com", "http://signup")
    end

    test "non-existing user, by email, when email is invalid" do
      assert send_login_email("new@", &signup_url/1, &login_url/1) ==
        {:error, :email_invalid}

      assert_no_emails_delivered()
    end

    test "non-existing user, by username" do
      assert send_login_email("idontexist", &signup_url/1, &login_url/1) ==
        {:error, :user_not_found}

      assert_no_emails_delivered()
    end
  end

end
