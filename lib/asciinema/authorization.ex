defmodule Asciinema.Authorization do
  alias Asciinema.Accounts.User
  alias Asciinema.Recordings.Asciicast
  alias Asciinema.Streaming.LiveStream

  defmodule Policy do
    def can?(nil, _action, _thing) do
      false
    end

    def can?(%User{is_admin: true}, _action, _thing) do
      true
    end

    def can?(_user, :make_featured, %Asciicast{}), do: false
    def can?(_user, :make_not_featured, %Asciicast{}), do: false

    def can?(user, _action, %Asciicast{user_id: uid}) do
      user.id == uid
    end

    def can?(user, _action, %LiveStream{user_id: uid}) do
      user.id == uid
    end

    def can?(user, :update, %User{id: uid}) do
      user.id == uid
    end

    def can?(_user, _action, _thing) do
      false
    end
  end

  def can?(user, action, thing) do
    action =
      case action do
        :edit -> :update
        action -> action
      end

    Policy.can?(user, action, thing)
  end

  defmodule ForbiddenError do
    defexception plug_status: 403, message: "Forbidden"
  end

  def can!(user, action, thing) do
    if can?(user, action, thing) do
      :ok
    else
      raise ForbiddenError
    end
  end
end
