defmodule Asciinema.UserTest do
  use Asciinema.ModelCase

  alias Asciinema.User

  @valid_attrs %{email: "test@example.com"}
  @invalid_attrs %{}

  test "signup changeset with valid attributes" do
    changeset = User.signup_changeset(@valid_attrs)
    assert changeset.valid?
  end

  test "signup changeset with invalid attributes" do
    changeset = User.signup_changeset(@invalid_attrs)
    refute changeset.valid?
  end
end
