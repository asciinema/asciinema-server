defmodule AsciinemaTest do
  use Asciinema.DataCase
  use Oban.Testing, repo: Asciinema.Repo

  describe "send_login_email/1" do
    import Asciinema, only: [send_login_email: 3]

    defp signup_url(_), do: "http://signup"
    defp login_url(_), do: "http://login"

    test "existing user, by email" do
      user = fixture(:user)

      assert send_login_email(user.email, &signup_url/1, &login_url/1) == :ok

      assert_enqueued(
        worker: Asciinema.Emails.Job,
        args: %{"type" => "login", "to" => user.email, "url" => "http://login"}
      )
    end

    test "existing user, by username" do
      user = fixture(:user)

      assert send_login_email(user.username, &signup_url/1, &login_url/1) == :ok

      assert_enqueued(
        worker: Asciinema.Emails.Job,
        args: %{"type" => "login", "to" => user.email, "url" => "http://login"}
      )
    end

    test "non-existing user, by email" do
      assert send_login_email("new@example.com", &signup_url/1, &login_url/1) == :ok

      assert_enqueued(
        worker: Asciinema.Emails.Job,
        args: %{"type" => "signup", "to" => "new@example.com", "url" => "http://signup"}
      )
    end

    test "non-existing user, by email, when email is invalid" do
      assert send_login_email("new@", &signup_url/1, &login_url/1) ==
               {:error, :email_invalid}

      refute_enqueued(worker: Asciinema.Emails.Job)
    end

    test "non-existing user, by username" do
      assert send_login_email("idontexist", &signup_url/1, &login_url/1) ==
               {:error, :user_not_found}

      refute_enqueued(worker: Asciinema.Emails.Job)
    end
  end
end
