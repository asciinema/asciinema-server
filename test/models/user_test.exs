defmodule Asciinema.UserTest do
  use Asciinema.ModelCase

  alias Asciinema.User

  @valid_attrs %{email: "test@example.com", username: "test"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.create_changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.create_changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
