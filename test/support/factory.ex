defmodule Asciinema.Factory do
  use ExMachina.Ecto, repo: Asciinema.Repo
  alias Asciinema.Accounts.User
  alias Asciinema.Asciicasts.Asciicast

  def user_factory do
    %User{username: sequence(:username, &"username-#{&1}"),
          email: sequence(:email, &"email-#{&1}@example.com"),
          auth_token: Crypto.random_token(20)}
  end

  def asciicast_factory do
    %Asciicast{user: build(:user),
               version: 2,
               duration: 123.45,
               terminal_columns: 80,
               terminal_lines: 24,
               secret_token: sequence(:secret_token, &"sekrit-#{&1}"),
               snapshot: [[["foo", %{}]], [["bar", %{}]]]}
  end
end
