defmodule Asciinema.UserTest do
  use Asciinema.ModelCase

  alias Asciinema.User

  @valid_attrs %{asciicasts_private_by_default: true, auth_token: "some content", email: "some content", name: "some content", temporary_username: "some content", theme_name: "some content", username: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
