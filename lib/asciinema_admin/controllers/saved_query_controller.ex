defmodule AsciinemaAdmin.SavedQueryController do
  use AsciinemaAdmin, :controller

  alias AsciinemaAdmin.SavedQueries

  def create(conn, params) do
    return_to =
      params["return_to"] || index_path(params["entity"], params["filter"], params["sort"])

    case SavedQueries.create(params) do
      {:ok, saved_query} ->
        conn
        |> put_flash(:info, "Saved query \"#{saved_query.name}\".")
        |> redirect(to: return_to)

      {:error, changeset} ->
        conn
        |> put_flash(:error, save_error_message(changeset))
        |> redirect(to: return_to)
    end
  end

  defp save_error_message(changeset) do
    cond do
      Keyword.has_key?(changeset.errors, :normalized_filter) ->
        "This search is already saved with the same sort."

      name_taken?(changeset) ->
        "A saved query with this name already exists."

      true ->
        "Could not save the query. Please check the name and try again."
    end
  end

  defp name_taken?(changeset) do
    match?({"has already been taken", _}, Keyword.get(changeset.errors, :name))
  end

  def update(conn, %{"id" => id, "name" => name} = params) do
    saved_query = SavedQueries.get!(id)

    return_to =
      params["return_to"] || index_path(saved_query.entity, saved_query.filter, saved_query.sort)

    case SavedQueries.rename(saved_query, name) do
      {:ok, saved_query} ->
        conn
        |> put_flash(:info, "Renamed saved query to \"#{saved_query.name}\".")
        |> redirect(to: return_to)

      {:error, changeset} ->
        conn
        |> put_flash(:error, save_error_message(changeset))
        |> redirect(to: return_to)
    end
  end

  def delete(conn, %{"id" => id} = params) do
    saved_query = SavedQueries.get!(id)
    {:ok, _} = SavedQueries.delete(saved_query)

    return_to =
      params["return_to"] || index_path(saved_query.entity, saved_query.filter, saved_query.sort)

    conn
    |> put_flash(:info, "Deleted saved query \"#{saved_query.name}\".")
    |> redirect(to: return_to)
  end

  defp index_path("users", filter, sort), do: ~p"/admin/users?#{%{q: filter, sort: sort}}"

  defp index_path("recordings", filter, sort),
    do: ~p"/admin/recordings?#{%{q: filter, sort: sort}}"

  defp index_path("streams", filter, sort), do: ~p"/admin/streams?#{%{q: filter, sort: sort}}"
  defp index_path(_, _filter, _sort), do: ~p"/admin"
end
