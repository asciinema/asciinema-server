defmodule AsciinemaWeb.AuthorizationTest do
  use ExUnit.Case, async: true
  alias Asciinema.Accounts.User
  alias Asciinema.Recordings.Asciicast
  alias Asciinema.Streaming.Stream
  alias AsciinemaWeb.Authorization

  describe "can?/3 :edit action" do
    test "delegates to update for asciicast owner" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :edit, asciicast)
    end

    test "delegates to update for asciicast non-owner" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :edit, asciicast)
    end

    test "delegates to update for guest on asciicast" do
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :edit, asciicast)
    end

    test "delegates to update for stream owner" do
      user = %User{id: 1}
      stream = %Stream{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :edit, stream)
    end

    test "delegates to update for stream non-owner" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :edit, stream)
    end

    test "delegates to update for guest on stream" do
      stream = %Stream{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :edit, stream)
    end
  end

  describe "can?/3 :iframe action" do
    test "delegates to show for public asciicast" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      assert Authorization.can?(user, :iframe, asciicast)
    end

    test "delegates to show for guest on private asciicast" do
      asciicast = %Asciicast{user_id: 1, visibility: :private}

      refute Authorization.can?(nil, :iframe, asciicast)
    end

    test "delegates to show for guest on public asciicast" do
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      assert Authorization.can?(nil, :iframe, asciicast)
    end

    test "delegates to show for public stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :public}

      assert Authorization.can?(user, :iframe, stream)
    end

    test "delegates to show for guest on private stream" do
      stream = %Stream{user_id: 1, visibility: :private}

      refute Authorization.can?(nil, :iframe, stream)
    end

    test "delegates to show for guest on public stream" do
      stream = %Stream{user_id: 1, visibility: :public}

      assert Authorization.can?(nil, :iframe, stream)
    end
  end
end
