defmodule AsciinemaAdmin.Dashboard do
  @moduledoc """
  Global counts and recent-activity lists for the admin dashboard.

  Thin wrappers over the entity contexts' typed query layer
  (`Accounts.count/1` + `list/3`, etc.) — the same path the admin index pages
  use — so filter/sort semantics (notably the streams "activity" order) have a
  single source of truth. Per-entity time-series (`signups_by_day`,
  `recordings_by_day`) live in those contexts directly.
  """

  alias Asciinema.{Accounts, Recordings, Streaming}
  alias Asciinema.Accounts.Query, as: UserQuery
  alias Asciinema.Recordings.Query, as: RecordingQuery
  alias Asciinema.Streaming.Query, as: StreamQuery

  @doc "Total number of users."
  def user_count, do: Accounts.count(%UserQuery{scope: :admin})

  @doc "Total number of recordings (archived included)."
  def recording_count, do: Recordings.count(%RecordingQuery{scope: :admin, archived: :include})

  @doc "Total number of streams."
  def stream_count, do: Streaming.count(%StreamQuery{scope: :admin})

  @doc "Number of currently-live streams."
  def live_stream_count, do: Streaming.count(%StreamQuery{scope: :admin, filters: [live: true]})

  @doc "The `limit` newest users, newest first."
  def recent_signups(limit) do
    Accounts.list(
      %UserQuery{scope: :admin, filters: [registered: true], sort: {:created, :desc}},
      limit
    )
  end

  @doc "The `limit` newest recordings (any visibility, archived included), newest first."
  def recent_recordings(limit) do
    Recordings.list(
      %RecordingQuery{scope: :admin, archived: :include, sort: {:created, :desc}},
      limit,
      preload: [:user]
    )
  end

  @doc "The `limit` most active streams — live first, then most recently started."
  def recent_stream_activity(limit) do
    Streaming.list(%StreamQuery{scope: :admin, sort: {:activity, :desc}}, limit, preload: [:user])
  end
end
