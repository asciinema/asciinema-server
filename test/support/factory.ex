defmodule Asciinema.Factory do
  use ExMachina.Ecto, repo: Asciinema.Repo
  alias Asciinema.Accounts.User

  def user_factory do
    %User{username: sequence(:username, &"username-#{&1}"),
          email: sequence(:email, &"email-#{&1}@example.com"),
          auth_token: Crypto.random_token(20)}
  end
end
