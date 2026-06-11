defmodule AsciinemaAdmin.IndexQuery do
  @moduledoc """
  Builds typed index query state from admin URL params.
  """

  alias AsciinemaAdmin.{QueryParser, QuerySort, SavedQueries}

  @entities [:users, :recordings, :streams]

  def build(entity, params) when entity in @entities do
    q = canonical_q(entity, params)
    parser = QueryParser.parse(entity, q)
    sort_param = canonical_sort(entity, params)
    sort_result = QuerySort.parse(entity, sort_param)

    {sort, sort_errors} =
      case sort_result do
        {:ok, sort} -> {sort, []}
        {:error, error} -> {QuerySort.fetch!(entity, QuerySort.default_param(entity)), [error]}
      end

    errors = parser.errors ++ sort_errors
    query = if errors == [], do: QueryParser.to_query(parser, sort.sort)
    normalized_filter = parser.normalized_filter

    active_saved_query =
      if errors == [] do
        SavedQueries.matching(entity, normalized_filter, sort.param)
      end

    %{
      entity: entity,
      q: q,
      parser: parser,
      normalized_filter: normalized_filter,
      sort: sort,
      sort_param: sort_param,
      sort_options: QuerySort.options(entity),
      errors: errors,
      valid?: errors == [],
      query: query,
      saved_queries: SavedQueries.list(entity),
      active_saved_query: active_saved_query,
      query_params: query_params(q, sort_param)
    }
  end

  defp query_params("", sort), do: %{sort: sort}
  defp query_params(q, sort), do: %{q: q, sort: sort}

  defp canonical_q(_entity, params), do: params["q"] || ""

  defp canonical_sort(entity, %{"sort" => sort}) when is_binary(sort) and sort != "" do
    case QuerySort.normalize_param(sort) do
      "" -> QuerySort.default_param(entity)
      normalized -> normalized
    end
  end

  defp canonical_sort(entity, _params), do: QuerySort.default_param(entity)
end
