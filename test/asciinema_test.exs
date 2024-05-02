defmodule AsciinemaTest do
  import Asciinema.Factory
  use Asciinema.DataCase
  use Oban.Testing, repo: Asciinema.Repo
  alias Asciinema.{Accounts, Recordings}

  describe "create_user/1" do
    test "succeeds when email not taken" do
      assert {:ok, _} = Asciinema.create_user(%{email: "test@example.com"})
      assert {:error, :email_taken} = Asciinema.create_user(%{email: "test@example.com"})
      assert {:error, :email_taken} = Asciinema.create_user(%{email: "TEST@EXAMPLE.COM"})
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
      insert(:user, email: "test@example.com")

      assert Asciinema.send_login_email("TEST@EXAMPLE.COM", true, Routes) == :ok

      assert_enqueued(
        worker: Asciinema.Emails.Job,
        args: %{"type" => "login", "to" => "test@example.com", "url" => "http://login"}
      )
    end

    test "existing user, by username" do
      insert(:user, username: "foobar", email: "foobar123@example.com")

      assert Asciinema.send_login_email("foobar", true, Routes) == :ok

      assert_enqueued(
        worker: Asciinema.Emails.Job,
        args: %{"type" => "login", "to" => "foobar123@example.com", "url" => "http://login"}
      )
    end

    test "non-existing user, by email" do
      assert Asciinema.send_login_email("NEW@EXAMPLE.COM", true, Routes) ==
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

  describe "hide_unclaimed_recordings/1" do
    test "sets archived_at on matching asciicasts" do
      tmp_user = insert(:temporary_user, email: nil)

      asciicast_1 =
        insert(:asciicast,
          user: tmp_user,
          inserted_at: Timex.shift(Timex.now(), days: -2)
        )

      asciicast_2 =
        insert(:asciicast,
          user: tmp_user,
          inserted_at: Timex.shift(Timex.now(), days: -4)
        )

      asciicast_3 =
        insert(:asciicast,
          user: tmp_user,
          inserted_at: Timex.shift(Timex.now(), days: -10),
          archivable: false
        )

      assert Asciinema.hide_unclaimed_recordings(3) == 1
      assert Recordings.get_asciicast(asciicast_1.id).archived_at == nil
      assert Recordings.get_asciicast(asciicast_2.id).archived_at != nil
      assert Recordings.get_asciicast(asciicast_3.id).archived_at == nil
    end
  end

  describe "delete_unclaimed_recordings/1" do
    test "deletes matching asciicasts" do
      tmp_user = insert(:temporary_user, email: nil)

      asciicast_1 =
        insert(:asciicast,
          user: tmp_user,
          inserted_at: Timex.shift(Timex.now(), days: -2)
        )

      asciicast_2 =
        insert(:asciicast,
          user: tmp_user,
          inserted_at: Timex.shift(Timex.now(), days: -4)
        )

      asciicast_3 =
        insert(:asciicast,
          user: tmp_user,
          inserted_at: Timex.shift(Timex.now(), days: -10),
          archivable: false
        )

      assert Asciinema.delete_unclaimed_recordings(3) == 1
      assert Recordings.get_asciicast(asciicast_1.id) != nil
      assert Recordings.get_asciicast(asciicast_2.id) == nil
      assert Recordings.get_asciicast(asciicast_3.id) != nil
    end
  end
end
