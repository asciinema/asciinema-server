defmodule AsciinemaTest do
  import Asciinema.Factory
  use Asciinema.DataCase
  use Oban.Testing, repo: Asciinema.Repo
  alias Asciinema.Accounts

  describe "create_user/1" do
    test "succeeds when email not taken" do
      assert {:ok, _} = Asciinema.create_user(%{email: "test@example.com"})
      assert {:error, :email_taken} = Asciinema.create_user(%{email: "test@example.com"})
    end
  end

  describe "create_user_from_signup_token/1" do
    test "succeeds when email not taken" do
      # TODO don't reach to Accounts
      token = Accounts.signup_token("test@example.com")
      assert {:ok, _} = Asciinema.create_user_from_signup_token(token)
    end
  end

  describe "send_login_email/3" do
    defmodule Routes do
      def signup_url(_), do: "http://signup"
      def login_url(_), do: "http://login"
    end

    test "existing user, by email" do
      user = insert(:user)

      assert Asciinema.send_login_email(user.email, true, Routes) == :ok

      assert_enqueued(
        worker: Asciinema.Emails.Job,
        args: %{"type" => "login", "to" => user.email, "url" => "http://login"}
      )
    end

    test "existing user, by username" do
      user = insert(:user)

      assert Asciinema.send_login_email(user.username, true, Routes) == :ok

      assert_enqueued(
        worker: Asciinema.Emails.Job,
        args: %{"type" => "login", "to" => user.email, "url" => "http://login"}
      )
    end

    test "non-existing user, by email" do
      assert Asciinema.send_login_email("new@example.com", true, Routes) ==
               :ok

      assert_enqueued(
        worker: Asciinema.Emails.Job,
        args: %{"type" => "signup", "to" => "new@example.com", "url" => "http://signup"}
      )
    end

    test "non-existing user, by email, when sign up is disabled" do
      assert Asciinema.send_login_email("new@example.com", false, Routes) ==
               {:error, :user_not_found}

      refute_enqueued(worker: Asciinema.Emails.Job)
    end

    test "non-existing user, by email, when email is invalid" do
      assert Asciinema.send_login_email("new@", true, Routes) ==
               {:error, :email_invalid}

      refute_enqueued(worker: Asciinema.Emails.Job)
    end

    test "non-existing user, by username" do
      assert Asciinema.send_login_email("idontexist", true, Routes) ==
               {:error, :user_not_found}

      refute_enqueued(worker: Asciinema.Emails.Job)
    end
  end

  describe "merge_accounts/1" do
    test "succeeds" do
      [user1, user2] = insert_pair(:user)
      id2 = user2.id
      insert(:asciicast, user: user1)
      insert(:asciicast, user: user2)
      insert(:api_token, user: user1)
      insert(:api_token, user: user2)
      insert(:live_stream, user: user1)
      insert(:live_stream, user: user2)

      assert {:ok, %{id: ^id2}} = Asciinema.merge_accounts(user1, user2)
    end
  end

  describe "delete_user!/1" do
    test "succeeds" do
      user = insert(:user)
      insert(:asciicast, user: user)
      insert(:api_token, user: user)
      insert(:live_stream, user: user)

      assert :ok = Asciinema.delete_user!(user)
    end
  end
end
