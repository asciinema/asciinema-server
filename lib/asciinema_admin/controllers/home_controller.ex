defmodule AsciinemaAdmin.HomeController do
  use AsciinemaAdmin, :controller

  alias Asciinema.{Accounts, Recordings}
  alias AsciinemaAdmin.Dashboard

  @sparkline_days 30
  @recent_limit 5

  def show(conn, _params) do
    render(conn, :show,
      page_title: "Dashboard",
      user_count: Dashboard.user_count(),
      recording_count: Dashboard.recording_count(),
      stream_count: Dashboard.stream_count(),
      live_stream_count: Dashboard.live_stream_count(),
      signups_by_day: Accounts.signups_by_day(@sparkline_days),
      recordings_by_day: Recordings.recordings_by_day(@sparkline_days),
      recent_signups: Dashboard.recent_signups(@recent_limit),
      recent_recordings: Dashboard.recent_recordings(@recent_limit),
      recent_streams: Dashboard.recent_stream_activity(@recent_limit)
    )
  end
end
