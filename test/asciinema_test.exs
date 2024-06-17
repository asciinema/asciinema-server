defmodule AsciinemaTest do
  import Asciinema.Factory
  import Swoosh.TestAssertions
  use Asciinema.DataCase
  use Oban.Testing, repo: Asciinema.Repo
  alias Asciinema.Recordings

  @urls Asciinema.TestUrlProvider

  describe "create_user/1" do
    test "succeeds when email not taken" do
      assert {:ok, _} = Asciinema.create_user(%{email: "test@example.com"})
      assert {:error, :email_taken} = Asciinema.create_user(%{email: "test@example.com"})
      assert {:error, :email_taken} = Asciinema.create_user(%{email: "TEST@EXAMPLE.COM"})
    end
  end

  describe "create_user_from_sign_up_token/1" do
    test "succeeds when email not taken" do
      # TODO don't reach to Accounts
      {:ok, {:sign_up, token, _email}} =
        Asciinema.Accounts.generate_login_token("test@example.com")

      assert {:ok, _} = Asciinema.create_user_from_sign_up_token(token)
    end
  end

  describe "send_login_email/3" do
    test "existing user, by email" do
      insert(:user, email: "test@example.com")

      assert Asciinema.send_login_email("TEST@EXAMPLE.COM", @urls) == :ok

      assert_email_sent(to: [{nil, "test@example.com"}], subject: "Login to localhost")
    end

    test "existing user, by username" do
      insert(:user, username: "foobar", email: "foobar123@example.com")

      assert Asciinema.send_login_email("foobar", @urls) == :ok

      assert_email_sent(
        to: [{nil, "foobar123@example.com"}],
        subject: "Login to localhost"
      )
    end

    test "non-existing user, by email" do
      assert Asciinema.send_login_email("NEW@EXAMPLE.COM", @urls) == :ok

      assert_email_sent(to: [{nil, "new@example.com"}], subject: "Welcome to localhost")
    end

    test "non-existing user, by email, when registration is disabled" do
      assert Asciinema.send_login_email("new@example.com", @urls, register: false) ==
               {:error, :user_not_found}

      assert_no_email_sent()
    end

    test "non-existing user, by email, when email is invalid" do
      assert Asciinema.send_login_email("new@", @urls) == {:error, :email_invalid}

      assert_no_email_sent()
    end

    test "non-existing user, by username" do
      assert Asciinema.send_login_email("idontexist", @urls) == {:error, :user_not_found}

      assert_no_email_sent()
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
