defmodule Asciinema.Authorization do
  alias Asciinema.Accounts.User
  alias Asciinema.Recordings.Asciicast
  alias Asciinema.Streaming.Stream

  defmodule Policy do
    def can?(_user, :show, %Asciicast{visibility: :public}), do: true

    def can?(_user, :show, %Asciicast{
          id: secret_token,
          secret_token: secret_token,
          visibility: :unlisted
        }),
        do: true

    def can?(nil, _action, _thing), do: false
    def can?(%User{is_admin: true}, _action, _thing), do: true
    def can?(user, _action, %Asciicast{user_id: uid}), do: user.id == uid
    def can?(_user, :show, %Stream{visibility: v}) when v in [:public, :unlisted], do: true
    def can?(user, _action, %Stream{user_id: uid}), do: user.id == uid
    def can?(user, :update, %User{id: uid}), do: user.id == uid
    def can?(_user, _action, _thing), do: false
  end

  def can?(user, :edit, thing), do: can?(user, :update, thing)
  def can?(user, :iframe, thing), do: can?(user, :show, thing)
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
