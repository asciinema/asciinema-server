defmodule Asciinema.Users do
  import Ecto.Query, warn: false
  alias Asciinema.{Repo, User, ApiToken}

  def authenticate(api_token) do
    q = from u in User,
      join: at in ApiToken,
      on: at.user_id == u.id,
      select: {u, at.revoked_at},
      where: at.token == ^api_token

    case Repo.one(q) do
      nil ->
        {:error, :token_not_found}
      {%User{} = user, nil} ->
        {:ok, user}
      {%User{}, _} ->
        {:error, :token_revoked}
    end
  end

  def get_user_with_api_token(username, api_token) do
    case authenticate(api_token) do
      {:ok, %User{} = user} ->
        user
      {:error, :token_revoked} ->
        nil
      {:error, :token_not_found} ->
        create_user_with_api_token(username, api_token)
    end
  end

  def create_user_with_api_token(username, api_token) do
    user_changeset = User.temporary_changeset(username)

    {_, result} = Repo.transaction(fn ->
      with {:ok, %User{} = user} <- Repo.insert(user_changeset),
           api_token_changeset = ApiToken.create_changeset(user, api_token),
           {:ok, %ApiToken{}} <- Repo.insert(api_token_changeset) do
        user
      else
        _otherwise -> Repo.rollback(nil)
      end
    end)

    result
  end

  def get_api_token!(token) do
    Repo.get_by!(ApiToken, token: token)
  end

  def revoke_api_token!(api_token) do
    api_token
    |> ApiToken.revoke_changeset
    |> Repo.update!
  end
end
