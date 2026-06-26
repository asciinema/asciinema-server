defmodule AsciinemaTest do
  import Asciinema.Factory
  import Swoosh.TestAssertions
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo
  alias Asciinema.Recordings

  @urls Asciinema.TestUrlProvider

  describe "initiate_login/3" do
    test "existing user, by email" do
      insert(:user, email: "test@example.com")

      assert Asciinema.initiate_login("TEST@EXAMPLE.COM", @urls) == :ok

      assert_email_sent(to: [{nil, "test@example.com"}], subject: "Login to localhost")
    end

    test "existing user, by username" do
      insert(:user, username: "foobar", email: "foobar123@example.com")

      assert Asciinema.initiate_login("foobar", @urls) == :ok

      assert_email_sent(
        to: [{nil, "foobar123@example.com"}],
        subject: "Login to localhost"
      )
    end

    test "non-existing user, by email" do
      assert Asciinema.initiate_login("NEW@EXAMPLE.COM", @urls) == :ok

      assert_email_sent(to: [{nil, "new@example.com"}], subject: "Welcome to localhost")
    end

    test "non-existing user, by email, when registration is disabled" do
      assert Asciinema.initiate_login("new@example.com", @urls, register: false) ==
               {:error, :user_not_found}

      assert_no_email_sent()
    end

    test "non-existing user, by email, when email is invalid" do
      assert Asciinema.initiate_login("new@", @urls) == {:error, :email_invalid}

      assert_no_email_sent()
    end

    test "non-existing user, by username" do
      assert Asciinema.initiate_login("idontexist", @urls) == {:error, :user_not_found}

      assert_no_email_sent()
    end
  end

  describe "merge_accounts/1" do
    test "moves the source account's records to the destination and deletes it" do
      [src, dst] = insert_pair(:user)
      dst_id = dst.id
      insert(:asciicast, user: src)
      insert(:asciicast, user: dst)
      insert(:cli, user: src)
      insert(:cli, user: dst)
      insert(:stream, user: src)
      insert(:stream, user: dst)

      assert {:ok, %{id: ^dst_id}} = Asciinema.merge_accounts(src, dst)

      assert Asciinema.Accounts.get_user(src.id) == nil
      assert Repo.count(assoc(dst, :asciicasts)) == 2
      assert Repo.count(assoc(dst, :streams)) == 2
      assert Repo.count(assoc(dst, :clis)) == 2
    end
  end

  describe "delete_user!/1" do
    test "succeeds" do
      user = insert(:user)
      insert(:asciicast, user: user)
      insert(:cli, user: user)
      insert(:stream, user: user)

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
