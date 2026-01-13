defmodule Asciinema.AuthorizationTest do
  use ExUnit.Case, async: true
  alias Asciinema.Accounts.User
  alias Asciinema.Authorization
  alias Asciinema.Recordings.Asciicast
  alias Asciinema.Streaming.Stream

  describe "can?/3 for Asciicast" do
    test "owner can read its own private asciicast" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 1, visibility: :private}

      assert Authorization.can?(user, :show, asciicast)
    end

    test "owner can read its own unlisted asciicast accessed by id" do
      user = %User{id: 1}
      asciicast = %Asciicast{id: 123, user_id: 1, visibility: :unlisted, secret_token: "s3kr1t"}

      assert Authorization.can?(user, :show, asciicast)
    end

    test "owner can read its own unlisted asciicast via secret token" do
      user = %User{id: 1}
      asciicast = %Asciicast{id: "s3kr1t", user_id: 1, visibility: :unlisted, secret_token: "s3kr1t"}

      assert Authorization.can?(user, :show, asciicast)
    end

    test "any user can read an unlisted asciicast given it knows the secret token" do
      user = %User{id: 1}

      asciicast = %Asciicast{
        id: "s3kr1t",
        user_id: 2,
        visibility: :unlisted,
        secret_token: "s3kr1t"
      }

      assert Authorization.can?(user, :show, asciicast)
    end

    test "any user can read a public asciicast" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      assert Authorization.can?(user, :show, asciicast)
    end

    test "a guest can read a public asciicast" do
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      assert Authorization.can?(nil, :show, asciicast)
    end

    test "a guest cannot read a private asciicast" do
      asciicast = %Asciicast{user_id: 1, visibility: :private}

      refute Authorization.can?(nil, :show, asciicast)
    end

    test "a guest cannot read an unlisted asciicast accessed by id" do
      asciicast = %Asciicast{id: 123, user_id: 1, visibility: :unlisted, secret_token: "s3kr1t"}

      refute Authorization.can?(nil, :show, asciicast)
    end

    test "a guest can read an unlisted asciicast given it knows the secret token" do
      asciicast = %Asciicast{
        id: "s3kr1t",
        user_id: 1,
        visibility: :unlisted,
        secret_token: "s3kr1t"
      }

      assert Authorization.can?(nil, :show, asciicast)
    end

    test "non-owner cannot read a private asciicast" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 2, visibility: :private}

      refute Authorization.can?(user, :show, asciicast)
    end

    test "non-owner cannot read an unlisted asciicast accessed by id" do
      user = %User{id: 1}
      asciicast = %Asciicast{id: 123, user_id: 2, visibility: :unlisted, secret_token: "s3kr1t"}

      refute Authorization.can?(user, :show, asciicast)
    end

    test "admin can read a private asciicast" do
      admin = %User{id: 1, is_admin: true}
      asciicast = %Asciicast{user_id: 2, visibility: :private}

      assert Authorization.can?(admin, :show, asciicast)
    end

    test "admin can read an unlisted asciicast" do
      admin = %User{id: 1, is_admin: true}
      asciicast = %Asciicast{id: 123, user_id: 2, visibility: :unlisted, secret_token: "s3kr1t"}

      assert Authorization.can?(admin, :show, asciicast)
    end

    test "owner can update their own asciicast" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :update, asciicast)
    end

    test "non-owner cannot update someone else's asciicast" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :update, asciicast)
    end

    test "admin can update any asciicast" do
      admin = %User{id: 1, is_admin: true}
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      assert Authorization.can?(admin, :update, asciicast)
    end

    test "guest cannot update an asciicast" do
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :update, asciicast)
    end

    test "owner can delete their own asciicast" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :delete, asciicast)
    end

    test "non-owner cannot delete someone else's asciicast" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :delete, asciicast)
    end

    test "admin can delete any asciicast" do
      admin = %User{id: 1, is_admin: true}
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      assert Authorization.can?(admin, :delete, asciicast)
    end

    test "guest cannot delete an asciicast" do
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :delete, asciicast)
    end

    test "edit action delegates to update" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :edit, asciicast)
    end

    test "non-owner cannot edit someone else's asciicast" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :edit, asciicast)
    end

    test "guest cannot edit an asciicast" do
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :edit, asciicast)
    end

    test "iframe action delegates to show" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      assert Authorization.can?(user, :iframe, asciicast)
    end

    test "guest cannot iframe a private asciicast" do
      asciicast = %Asciicast{user_id: 1, visibility: :private}

      refute Authorization.can?(nil, :iframe, asciicast)
    end

    test "guest can iframe a public asciicast" do
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      assert Authorization.can?(nil, :iframe, asciicast)
    end
  end

  describe "can?/3 for Stream" do
    test "any user can see a public stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :public}

      assert Authorization.can?(user, :show, stream)
    end

    test "any user can see an unlisted stream given it knows the public token" do
      user = %User{id: 1}
      stream = %Stream{id: "t0k3n", user_id: 2, visibility: :unlisted, public_token: "t0k3n"}

      assert Authorization.can?(user, :show, stream)
    end

    test "a guest can see a public stream" do
      stream = %Stream{user_id: 1, visibility: :public}

      assert Authorization.can?(nil, :show, stream)
    end

    test "a guest cannot see a private stream" do
      stream = %Stream{user_id: 1, visibility: :private}

      refute Authorization.can?(nil, :show, stream)
    end

    test "a guest cannot see an unlisted stream accessed by id" do
      stream = %Stream{id: 123, user_id: 1, visibility: :unlisted, public_token: "t0k3n"}

      refute Authorization.can?(nil, :show, stream)
    end

    test "a guest can see an unlisted stream given it knows the public token" do
      stream = %Stream{id: "t0k3n", user_id: 1, visibility: :unlisted, public_token: "t0k3n"}

      assert Authorization.can?(nil, :show, stream)
    end

    test "owner can see their own private stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 1, visibility: :private}

      assert Authorization.can?(user, :show, stream)
    end

    test "owner can see their own unlisted stream accessed by id" do
      user = %User{id: 1}
      stream = %Stream{id: 123, user_id: 1, visibility: :unlisted, public_token: "t0k3n"}

      assert Authorization.can?(user, :show, stream)
    end

    test "owner can see their own unlisted stream via public token" do
      user = %User{id: 1}
      stream = %Stream{id: "t0k3n", user_id: 1, visibility: :unlisted, public_token: "t0k3n"}

      assert Authorization.can?(user, :show, stream)
    end

    test "non-owner cannot see a private stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :private}

      refute Authorization.can?(user, :show, stream)
    end

    test "non-owner cannot see an unlisted stream accessed by id" do
      user = %User{id: 1}
      stream = %Stream{id: 123, user_id: 2, visibility: :unlisted, public_token: "t0k3n"}

      refute Authorization.can?(user, :show, stream)
    end

    test "admin can see a private stream" do
      admin = %User{id: 1, is_admin: true}
      stream = %Stream{user_id: 2, visibility: :private}

      assert Authorization.can?(admin, :show, stream)
    end

    test "admin can see an unlisted stream accessed by id" do
      admin = %User{id: 1, is_admin: true}
      stream = %Stream{id: 123, user_id: 2, visibility: :unlisted, public_token: "t0k3n"}

      assert Authorization.can?(admin, :show, stream)
    end

    test "owner can update their own stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :update, stream)
    end

    test "non-owner cannot update someone else's stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :update, stream)
    end

    test "admin can update any stream" do
      admin = %User{id: 1, is_admin: true}
      stream = %Stream{user_id: 2, visibility: :public}

      assert Authorization.can?(admin, :update, stream)
    end

    test "guest cannot update a stream" do
      stream = %Stream{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :update, stream)
    end

    test "owner can delete their own stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 1, visibility: :public}

      assert Authorization.can?(user, :delete, stream)
    end

    test "non-owner cannot delete someone else's stream" do
      user = %User{id: 1}
      stream = %Stream{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :delete, stream)
    end

    test "admin can delete any stream" do
      admin = %User{id: 1, is_admin: true}
      stream = %Stream{user_id: 2, visibility: :public}

      assert Authorization.can?(admin, :delete, stream)
    end

    test "guest cannot delete a stream" do
      stream = %Stream{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :delete, stream)
    end
  end

  describe "can?/3 for User" do
    test "user can update their own profile" do
      user = %User{id: 1}
      target_user = %User{id: 1}

      assert Authorization.can?(user, :update, target_user)
    end

    test "user cannot update someone else's profile" do
      user = %User{id: 1}
      target_user = %User{id: 2}

      refute Authorization.can?(user, :update, target_user)
    end

    test "admin can update any user" do
      admin = %User{id: 1, is_admin: true}
      target_user = %User{id: 2}

      assert Authorization.can?(admin, :update, target_user)
    end

    test "guest cannot update a user" do
      target_user = %User{id: 1}

      refute Authorization.can?(nil, :update, target_user)
    end
  end

  describe "deny-by-default" do
    test "unknown action is denied for non-owner" do
      user = %User{id: 1}
      asciicast = %Asciicast{user_id: 2, visibility: :public}

      refute Authorization.can?(user, :unknown_action, asciicast)
    end

    test "unknown action is denied for guest" do
      asciicast = %Asciicast{user_id: 1, visibility: :public}

      refute Authorization.can?(nil, :unknown_action, asciicast)
    end

    test "unknown resource type is denied" do
      user = %User{id: 1}

      refute Authorization.can?(user, :show, %{some: "map"})
    end
  end
end
