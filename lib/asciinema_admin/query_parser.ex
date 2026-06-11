defmodule AsciinemaAdmin.QueryParser do
  @moduledoc """
  Parser for the compact admin `q` syntax.
  """

  alias Asciinema.Accounts.Query, as: UserQuery
  alias Asciinema.Recordings.Query, as: RecordingQuery
  alias Asciinema.Streaming.Query, as: StreamQuery

  @entities [:users, :recordings, :streams]
  @visibility_values ~w[public unlisted private]

  defstruct entity: nil,
            raw: "",
            normalized_filter: "",
            filters: [],
            archived: nil,
            errors: []

  def parse(entity, raw) when entity in @entities do
    raw = raw || ""
    tokens = String.split(raw, ~r/\s+/, trim: true)

    acc = %{
      entity: entity,
      raw: raw,
      bare: [],
      structured: [],
      seen: MapSet.new(),
      filters: [],
      archived: nil,
      errors: []
    }

    result =
      tokens
      |> Enum.reduce(acc, &parse_token/2)
      |> finalize()

    struct!(__MODULE__, result)
  end

  def valid?(%__MODULE__{errors: []}), do: true
  def valid?(%__MODULE__{}), do: false

  def to_query(%__MODULE__{entity: :users, filters: filters}, sort) do
    %UserQuery{scope: :admin, filters: filters, sort: sort}
  end

  def to_query(%__MODULE__{entity: :recordings, filters: filters, archived: archived}, sort) do
    %RecordingQuery{scope: :admin, archived: archived || :include, filters: filters, sort: sort}
  end

  def to_query(%__MODULE__{entity: :streams, filters: filters}, sort) do
    %StreamQuery{scope: :admin, filters: filters, sort: sort}
  end

  defp parse_token(token, acc) do
    case String.split(token, ":", parts: 2) do
      [name, value] when name != "" ->
        parse_structured(String.downcase(name), String.trim(value), token, acc)

      _ ->
        %{acc | bare: acc.bare ++ [token]}
    end
  end

  defp parse_structured(_name, "", token, acc),
    do: add_error(acc, "Invalid token \"#{token}\": value is empty")

  defp parse_structured(name, value, _token, acc) do
    canonical = canonical_token(acc.entity, name)

    cond do
      is_nil(canonical) ->
        add_error(acc, "Unknown token: #{name}")

      MapSet.member?(acc.seen, canonical) ->
        add_error(acc, "Duplicate token: #{canonical}")

      true ->
        acc = %{acc | seen: MapSet.put(acc.seen, canonical)}

        case parse_value(acc.entity, canonical, value) do
          {:ok, filter, normalized} ->
            acc
            |> put_filter(canonical, filter)
            |> put_structured(canonical, normalized)

          {:error, message} ->
            add_error(acc, message)
        end
    end
  end

  defp canonical_token(:users, token)
       when token in ~w[id username email name created login recordings streams],
       do: token

  defp canonical_token(:recordings, token)
       when token in ~w[id title user visibility featured archived created duration size views stream audio],
       do: token

  defp canonical_token(:streams, token)
       when token in ~w[id title user visibility live scheduled audio created started current-viewers peak-viewers],
       do: token

  defp canonical_token(_entity, _token), do: nil

  defp parse_value(entity, token, value) do
    case {entity, token} do
      {_, "id"} ->
        parse_id(value, :id)

      {:users, "username"} ->
        {:ok, {:username, {:search, value}}, value}

      {:users, "email"} ->
        {:ok, {:email, {:search, value}}, value}

      {:users, "name"} ->
        {:ok, {:name, {:search, value}}, value}

      {:users, "created"} ->
        parse_datetime_condition("created", value, :created_at)

      {:users, "login"} ->
        parse_datetime_condition("login", value, :last_login_at)

      {:users, "recordings"} ->
        parse_integer_condition("recordings", value, :recording_count)

      {:users, "streams"} ->
        parse_integer_condition("streams", value, :stream_count)

      {entity, "title"} when entity in [:recordings, :streams] ->
        {:ok, {:title, {:search, value}}, value}

      {entity, "user"} when entity in [:recordings, :streams] ->
        parse_user(value)

      {entity, "visibility"} when entity in [:recordings, :streams] ->
        parse_visibility(value)

      {:recordings, "featured"} ->
        parse_bool(value, :featured)

      {:recordings, "archived"} ->
        with {:ok, bool, normalized} <- parse_bool_value(value) do
          archived = if bool, do: :only, else: :exclude
          {:ok, {:archived, archived}, normalized}
        end

      {:recordings, "created"} ->
        parse_datetime_condition("created", value, :created_at)

      {:recordings, "duration"} ->
        parse_duration_condition("duration", value, :duration)

      {:recordings, "size"} ->
        parse_size_condition("size", value, :compressed_size)

      {:recordings, "views"} ->
        parse_integer_condition("views", value, :views)

      {:recordings, "stream"} ->
        parse_bool_or_id(value, :stream)

      {:recordings, "audio"} ->
        parse_bool(value, :audio)

      {:streams, "live"} ->
        parse_bool(value, :live)

      {:streams, "scheduled"} ->
        parse_bool(value, :scheduled)

      {:streams, "audio"} ->
        parse_bool(value, :audio)

      {:streams, "created"} ->
        parse_datetime_condition("created", value, :created_at)

      {:streams, "started"} ->
        if String.downcase(value) == "never" do
          {:ok, {:last_started_at, :never}, "never"}
        else
          parse_datetime_condition("started", value, :last_started_at)
        end

      {:streams, "current-viewers"} ->
        parse_integer_condition("current-viewers", value, :current_viewer_count)

      {:streams, "peak-viewers"} ->
        parse_integer_condition("peak-viewers", value, :peak_viewer_count)
    end
  end

  defp put_filter(acc, "archived", {:archived, archived}), do: %{acc | archived: archived}

  defp put_filter(acc, _token, filter), do: %{acc | filters: acc.filters ++ [filter]}

  defp put_structured(acc, token, normalized) do
    %{acc | structured: acc.structured ++ [{token, "#{token}:#{normalized}"}]}
  end

  defp finalize(acc) do
    filters =
      case acc.entity do
        :users ->
          maybe_add_search(acc.filters, :identity, acc.bare)

        entity when entity in [:recordings, :streams] ->
          title_terms =
            acc.bare ++
              (acc.filters
               |> Enum.flat_map(fn
                 {:title, {:search, text}} -> [text]
                 _ -> []
               end))

          acc.filters
          |> Enum.reject(fn
            {:title, {:search, _}} -> true
            _ -> false
          end)
          |> maybe_add_search(:title, title_terms)
      end

    normalized =
      (acc.bare ++ (acc.structured |> Enum.sort_by(&elem(&1, 0)) |> Enum.map(&elem(&1, 1))))
      |> Enum.join(" ")

    %{
      entity: acc.entity,
      raw: acc.raw,
      normalized_filter: normalized,
      filters: filters,
      archived: acc.archived || if(acc.entity == :recordings, do: :include, else: nil),
      errors: Enum.reverse(acc.errors)
    }
  end

  defp maybe_add_search(filters, _field, []), do: filters

  defp maybe_add_search(filters, field, terms) do
    filters ++ [{field, {:search, Enum.join(terms, " ")}}]
  end

  defp parse_id(value, field) do
    case Integer.parse(value) do
      {id, ""} when id > 0 -> {:ok, {field, id}, to_string(id)}
      _ -> {:error, "Invalid id \"#{value}\""}
    end
  end

  defp parse_user(value) do
    case Integer.parse(value) do
      {id, ""} when id > 0 -> {:ok, {:user, id}, to_string(id)}
      _ -> {:ok, {:user, value}, value}
    end
  end

  defp parse_visibility(value) do
    normalized = String.downcase(value)

    if normalized in @visibility_values do
      {:ok, {:visibility, String.to_existing_atom(normalized)}, normalized}
    else
      {:error, "Invalid visibility \"#{value}\"; expected public, unlisted, or private"}
    end
  end

  defp parse_bool(value, field) do
    with {:ok, bool, normalized} <- parse_bool_value(value) do
      {:ok, {field, bool}, normalized}
    end
  end

  defp parse_bool_or_id(value, field) do
    case parse_bool_value(value) do
      {:ok, bool, normalized} ->
        {:ok, {field, bool}, normalized}

      {:error, _} ->
        parse_id(value, field)
    end
  end

  defp parse_bool_value(value) do
    case String.downcase(value) do
      "yes" -> {:ok, true, "yes"}
      "true" -> {:ok, true, "yes"}
      "no" -> {:ok, false, "no"}
      "false" -> {:ok, false, "no"}
      _ -> {:error, "Invalid boolean \"#{value}\"; expected yes, no, true, or false"}
    end
  end

  defp parse_datetime_condition(name, value, field) do
    parse_condition(name, value, &parse_datetime_value/2, field, :datetime)
  end

  defp parse_duration_condition(name, value, field) do
    parse_condition(name, value, &parse_duration_value/2, field, :duration)
  end

  defp parse_size_condition(name, value, field) do
    parse_condition(name, value, &parse_size_value/2, field, :size)
  end

  defp parse_integer_condition(name, value, field) do
    parse_condition(name, value, &parse_integer_value/2, field, :integer)
  end

  defp parse_condition(name, value, parser, field, type) do
    cond do
      String.contains?(value, "..") ->
        parse_range(name, value, parser, field, type)

      String.starts_with?(value, [">=", "<=", ">", "<"]) ->
        parse_comparison(name, value, parser, field, type)

      type == :datetime ->
        parse_datetime_equality(name, value, field)

      true ->
        parse_equality(name, value, parser, field)
    end
  end

  defp parse_equality(name, value, parser, field) do
    with {:ok, parsed, normalized} <- parser.(value, :equality) do
      {:ok, {field, {:eq, parsed}}, normalized}
    else
      {:error, message} -> {:error, "Invalid #{name} \"#{value}\": #{message}"}
    end
  end

  defp parse_range(name, value, parser, field, type) do
    case String.split(value, "..", parts: 2) do
      ["", _] ->
        {:error, "Open-ended ranges are not supported; use >= or <= instead"}

      [_, ""] ->
        {:error, "Open-ended ranges are not supported; use >= or <= instead"}

      [from_raw, to_raw] ->
        from_mode = if type == :datetime, do: :range_start, else: :range
        to_mode = if type == :datetime, do: :range_end, else: :range

        with {:ok, from_value, from_norm} <- parser.(from_raw, from_mode),
             {:ok, to_value, to_norm} <- parser.(to_raw, to_mode) do
          {:ok, {field, {:between, from_value, to_value}}, "#{from_norm}..#{to_norm}"}
        else
          {:error, message} -> {:error, "Invalid #{name} range: #{message}"}
        end
    end
  end

  defp parse_comparison(name, value, parser, field, type) do
    {op, raw} =
      cond do
        String.starts_with?(value, ">=") -> {:gte, String.replace_prefix(value, ">=", "")}
        String.starts_with?(value, "<=") -> {:lte, String.replace_prefix(value, "<=", "")}
        String.starts_with?(value, ">") -> {:gt, String.replace_prefix(value, ">", "")}
        String.starts_with?(value, "<") -> {:lt, String.replace_prefix(value, "<", "")}
      end

    mode =
      if type == :datetime and op in [:gt, :lte] do
        :comparison_end
      else
        :comparison_start
      end

    with {:ok, parsed, normalized} <- parser.(raw, mode) do
      {:ok, {field, {op, parsed}}, "#{op_symbol(op)}#{normalized}"}
    else
      {:error, message} -> {:error, "Invalid #{name} \"#{value}\": #{message}"}
    end
  end

  defp parse_datetime_equality(name, value, field) do
    with {:ok, parsed, normalized} <- parse_datetime_value(value, :equality) do
      case parsed do
        {:between, from_dt, to_dt} -> {:ok, {field, {:between, from_dt, to_dt}}, normalized}
        from_dt -> {:ok, {field, {:gte, from_dt}}, normalized}
      end
    else
      {:error, message} -> {:error, "Invalid #{name} \"#{value}\": #{message}"}
    end
  end

  defp parse_datetime_value(raw, mode) do
    value = String.downcase(String.trim(raw))

    cond do
      Regex.match?(~r/^\d+[mhd]$/, value) ->
        {n, ""} = Integer.parse(String.slice(value, 0..-2//1))
        unit = String.last(value)
        seconds = relative_seconds(n, unit)

        {:ok, DateTime.utc_now() |> DateTime.add(-seconds) |> DateTime.truncate(:second),
         "#{n}#{unit}"}

      value == "today" ->
        today = Date.utc_today()
        {:ok, {:between, day_start(today), day_end(today)}, "today"}

      true ->
        case Date.from_iso8601(value) do
          {:ok, date} ->
            parsed =
              case mode do
                :equality -> {:between, day_start(date), day_end(date)}
                :range_end -> day_end(date)
                :comparison_end -> day_end(date)
                _ -> day_start(date)
              end

            {:ok, parsed, Date.to_iso8601(date)}

          _ ->
            {:error, "expected today, YYYY-MM-DD, or a window like 30d"}
        end
    end
  end

  defp parse_duration_value(raw, _mode) do
    case Regex.run(~r/^(\d+)(s|m|h)$/i, String.trim(raw)) do
      [_, n, unit] ->
        seconds = relative_seconds(String.to_integer(n), String.downcase(unit))
        {:ok, seconds, "#{n}#{String.downcase(unit)}"}

      _ ->
        {:error, "use a unit such as 10s, 10m, or 1h"}
    end
  end

  defp parse_size_value(raw, _mode) do
    case Regex.run(~r/^(\d+)(b|kb|mb|gb)$/i, String.trim(raw)) do
      [_, n, unit] ->
        unit = String.downcase(unit)
        {:ok, String.to_integer(n) * size_multiplier(unit), "#{n}#{unit}"}

      _ ->
        {:error, "use a unit such as 100kb, 10mb, or 1gb"}
    end
  end

  defp parse_integer_value(raw, _mode) do
    case Integer.parse(String.trim(raw)) do
      {n, ""} when n >= 0 -> {:ok, n, to_string(n)}
      _ -> {:error, "expected a non-negative integer"}
    end
  end

  defp op_symbol(:gt), do: ">"
  defp op_symbol(:gte), do: ">="
  defp op_symbol(:lt), do: "<"
  defp op_symbol(:lte), do: "<="

  defp relative_seconds(n, "s"), do: n
  defp relative_seconds(n, "m"), do: n * 60
  defp relative_seconds(n, "h"), do: n * 60 * 60
  defp relative_seconds(n, "d"), do: n * 60 * 60 * 24

  defp size_multiplier("b"), do: 1
  defp size_multiplier("kb"), do: 1024
  defp size_multiplier("mb"), do: 1024 * 1024
  defp size_multiplier("gb"), do: 1024 * 1024 * 1024

  defp day_start(date), do: DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
  defp day_end(date), do: DateTime.new!(date, ~T[23:59:59], "Etc/UTC")

  defp add_error(acc, message), do: %{acc | errors: [message | acc.errors]}
end
