defmodule Asciinema.Authorization do
  alias Asciinema.Accounts.User

  def can?(nil, _action, _thing) do
    false
  end

  def can?(user, :update, %User{id: uid}) do
    user.id == uid
  end

  def can?(_user, _action, _thing) do
    false
  end
end
