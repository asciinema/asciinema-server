defmodule Asciinema.Authorization do
  alias Asciinema.Accounts.User
  alias Asciinema.Recordings.Asciicast
  alias Asciinema.Streaming.Stream

  defmodule Policy do
    # for asciicasts

    def can?(%User{id: uid}, _action, %Asciicast{user_id: uid}), do: true

    def can?(_user, :show, %Asciicast{id: token, secret_token: token, visibility: :unlisted}),
      do: true

    def can?(_user, :show, %Asciicast{visibility: :public}), do: true

    # for streams

    def can?(%User{id: uid}, _action, %Stream{user_id: uid}), do: true

    def can?(_user, :show, %Stream{id: token, public_token: token, visibility: :unlisted}),
      do: true

    def can?(_user, :show, %Stream{visibility: :public}), do: true

    # for user

    def can?(%User{id: uid}, :update, %User{id: uid}), do: true

    # as admin

    def can?(%User{is_admin: true}, _action, _thing), do: true

    # deny everything else

    def can?(_user, _action, _thing), do: false
  end

  def can?(user, action, thing), do: Policy.can?(user, action, thing)

  defmodule Scope do
    import Ecto.Query

    def filter(query, :asciicasts, %User{id: user_id}) do
      where(query, [a], a.visibility == :public or a.user_id == ^user_id)
    end

    def filter(query, :asciicasts, nil) do
      where(query, [a], a.visibility == :public)
    end

    def filter(query, :streams, %User{id: user_id}) do
      where(query, [s], s.visibility == :public or s.user_id == ^user_id)
    end

    def filter(query, :streams, nil) do
      where(query, [s], s.visibility == :public)
    end
  end

  def scope(query, relations, user), do: Scope.filter(query, relations, user)
end
