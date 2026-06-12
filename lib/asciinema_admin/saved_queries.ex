defmodule AsciinemaAdmin.SavedQueries do
  @moduledoc """
  Persistence API for shared admin saved queries.
  """

  import Ecto.Query
  alias Asciinema.Repo
  alias AsciinemaAdmin.{QueryParser, QuerySort, SavedQuery}

  @entities [:users, :recordings, :streams]

  def list(entity) when entity in @entities do
    entity
    |> to_string()
    |> list()
  end

  def list(entity) when is_binary(entity) do
    Repo.all(
      from(q in SavedQuery,
        where: q.entity == ^entity,
        order_by: [asc: fragment("lower(?)", q.name)]
      )
    )
  end

  def grouped do
    queries =
      Repo.all(
        from(q in SavedQuery, order_by: [asc: q.entity, asc: fragment("lower(?)", q.name)])
      )

    Enum.group_by(queries, &String.to_existing_atom(&1.entity))
  end

  def matching(_entity, "", _sort), do: nil

  def matching(entity, normalized_filter, sort) when entity in @entities do
    Repo.one(
      from(q in SavedQuery,
        where:
          q.entity == ^to_string(entity) and q.normalized_filter == ^normalized_filter and
            q.sort == ^sort,
        limit: 1
      )
    )
  end

  def get!(id), do: Repo.get!(SavedQuery, id)

  def create(attrs) do
    case normalize_attrs(attrs) do
      {:ok, attrs} ->
        %SavedQuery{}
        |> SavedQuery.changeset(attrs)
        |> Repo.insert()

      {:error, attrs, errors} ->
        changeset =
          %SavedQuery{}
          |> SavedQuery.changeset(attrs)
          |> Ecto.Changeset.add_error(:filter, Enum.join(errors, ", "))

        {:error, changeset}
    end
  end

  def rename(%SavedQuery{} = saved_query, name) do
    saved_query
    |> SavedQuery.changeset(%{"name" => name})
    |> Repo.update()
  end

  def delete(%SavedQuery{} = saved_query), do: Repo.delete(saved_query)

  def validate(entity, filter, sort) when entity in ~w[users recordings streams] do
    entity = String.to_existing_atom(entity)
    parsed = QueryParser.parse(entity, filter)
    sort_result = QuerySort.parse(entity, sort)

    errors =
      parsed.errors ++
        case sort_result do
          {:ok, _} -> []
          {:error, error} -> [error]
        end

    if errors == [] do
      {:ok, %{normalized_filter: parsed.normalized_filter, sort: elem(sort_result, 1).param}}
    else
      {:error, errors}
    end
  end

  def validate(_entity, _filter, _sort), do: {:error, ["Invalid saved query entity"]}

  defp normalize_attrs(attrs) do
    entity = attrs["entity"] || attrs[:entity]
    filter = attrs["filter"] || attrs[:filter] || ""
    sort = attrs["sort"] || attrs[:sort] || ""

    attrs = string_key_attrs(attrs)

    case validate(entity, filter, sort) do
      {:ok, parsed} ->
        {:ok,
         attrs
         |> Map.put("entity", entity)
         |> Map.put("filter", filter)
         |> Map.put("normalized_filter", parsed.normalized_filter)
         |> Map.put("sort", parsed.sort)}

      {:error, errors} ->
        {:error,
         attrs
         |> Map.put("entity", entity || "")
         |> Map.put("filter", filter)
         |> Map.put("normalized_filter", "")
         |> Map.put("sort", sort), errors}
    end
  end

  defp string_key_attrs(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end
end
