defmodule Asciinema.Authorization do
  alias Asciinema.Accounts.User
  alias Asciinema.Recordings.Asciicast
  alias Asciinema.Streaming.LiveStream

  defmodule Policy do
    def can?(nil, _action, _thing), do: false
    def can?(%User{is_admin: true}, _action, _thing), do: true
    def can?(_user, :make_featured, %Asciicast{}), do: false
    def can?(_user, :make_not_featured, %Asciicast{}), do: false
    def can?(user, _action, %Asciicast{user_id: uid}), do: user.id == uid
    def can?(user, _action, %LiveStream{user_id: uid}), do: user.id == uid
    def can?(user, :update, %User{id: uid}), do: user.id == uid
    def can?(_user, _action, _thing), do: false
  end

  def can?(user, action, thing) do
    action =
      case action do
        :edit -> :update
        action -> action
      end

    Policy.can?(user, action, thing)
  end
end
