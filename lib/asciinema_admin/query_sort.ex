defmodule AsciinemaAdmin.QuerySort do
  @moduledoc """
  Canonical admin index sort definitions.
  """

  @enforce_keys [:entity, :param, :label, :sort]
  defstruct [:entity, :param, :label, :sort, directions: [:asc, :desc]]

  @type entity :: :users | :recordings | :streams
  @type t :: %__MODULE__{}

  @defaults %{users: "created.desc", recordings: "created.desc", streams: "activity.desc"}

  def options(:users) do
    [
      sort(:users, "created.desc", "newest", {:created, :desc}),
      sort(:users, "created.asc", "oldest", {:created, :asc}),
      sort(
        :users,
        "last-login.desc",
        "recently active",
        {:last_login, :desc}
      ),
      sort(
        :users,
        "last-login.asc",
        "least recently active",
        {:last_login, :asc}
      ),
      sort(
        :users,
        "recordings.desc",
        "most recordings",
        {:recordings, :desc}
      ),
      sort(
        :users,
        "recordings.asc",
        "fewest recordings",
        {:recordings, :asc}
      ),
      sort(:users, "streams.desc", "most streams", {:streams, :desc}),
      sort(:users, "streams.asc", "fewest streams", {:streams, :asc})
    ]
  end

  def options(:recordings) do
    [
      sort(:recordings, "created.desc", "newest", {:created, :desc}),
      sort(:recordings, "created.asc", "oldest", {:created, :asc}),
      sort(:recordings, "duration.desc", "longest", {:duration, :desc}),
      sort(:recordings, "duration.asc", "shortest", {:duration, :asc}),
      sort(:recordings, "size.desc", "largest", {:size, :desc}),
      sort(:recordings, "size.asc", "smallest", {:size, :asc}),
      sort(:recordings, "views.desc", "most viewed", {:views, :desc}),
      sort(:recordings, "views.asc", "least viewed", {:views, :asc})
    ]
  end

  def options(:streams) do
    [
      sort(:streams, "activity.desc", "live first", {:activity, :desc}),
      sort(:streams, "activity.asc", "least active", {:activity, :asc}),
      sort(:streams, "created.desc", "newest", {:created, :desc}),
      sort(:streams, "created.asc", "oldest", {:created, :asc}),
      sort(:streams, "last-started.desc", "recently started", {:last_started, :desc}),
      sort(:streams, "last-started.asc", "least recently started", {:last_started, :asc}),
      sort(:streams, "current-viewers.desc", "most viewers now", {:current_viewers, :desc}),
      sort(:streams, "current-viewers.asc", "fewest viewers now", {:current_viewers, :asc}),
      sort(:streams, "peak-viewers.desc", "highest peak viewers", {:peak_viewers, :desc}),
      sort(:streams, "peak-viewers.asc", "lowest peak viewers", {:peak_viewers, :asc})
    ]
  end

  def default_param(entity), do: Map.fetch!(@defaults, entity)

  def parse(entity, value) do
    param = normalize_param(value) || default_param(entity)

    case Enum.find(options(entity), &(&1.param == param)) do
      nil -> {:error, "Invalid sort \"#{value}\""}
      sort -> {:ok, sort}
    end
  end

  def fetch!(entity, param) do
    entity
    |> options()
    |> Enum.find(&(&1.param == param)) || raise ArgumentError, "unknown sort #{inspect(param)}"
  end

  def sort_link_param(%__MODULE__{} = current, target_param) do
    target = fetch!(current.entity, target_param)

    if current.param == target.param and length(target.directions) == 2 do
      toggle_param(target.param)
    else
      target.param
    end
  end

  # the header always links via ".desc"; the arrow shows the actual current direction
  def sort_arrow(%__MODULE__{param: current_param}, target_param) do
    if sort_field(current_param) == sort_field(target_param) do
      case sort_field_direction(current_param) do
        "desc" -> " ↓"
        "asc" -> " ↑"
        _ -> ""
      end
    else
      ""
    end
  end

  def sort_arrow(_current, _param), do: ""

  defp sort_field(param), do: param |> String.split(".") |> List.first()
  defp sort_field_direction(param), do: param |> String.split(".") |> List.last()

  def normalize_param(nil), do: nil
  def normalize_param(""), do: nil

  def normalize_param(value) when is_binary(value),
    do: value |> String.trim() |> String.downcase()

  defp sort(entity, param, label, sort, directions \\ [:asc, :desc]) do
    %__MODULE__{
      entity: entity,
      param: param,
      label: label,
      sort: sort,
      directions: directions
    }
  end

  defp toggle_param(param) do
    cond do
      String.ends_with?(param, ".desc") -> String.replace_suffix(param, ".desc", ".asc")
      String.ends_with?(param, ".asc") -> String.replace_suffix(param, ".asc", ".desc")
    end
  end
end
