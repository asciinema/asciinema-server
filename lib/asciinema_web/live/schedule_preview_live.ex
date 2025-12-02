defmodule AsciinemaWeb.SchedulePreviewLive do
  use AsciinemaWeb, :live_view
  alias AsciinemaWeb.StreamHTML

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="schedule-preview" phx-hook="SchedulePreview">
      {render_result(@result)}
    </div>
    """
  end

  defp render_result({:ok, times}), do: render_times(%{times: times})
  defp render_result({:error, reason}), do: render_error(%{reason: reason})

  defp render_times(%{times: nil}), do: nil

  defp render_times(%{times: []} = assigns) do
    ~H"""
    <span class="text-warning">This expression doesn't match any future dates</span>
    """
  end

  defp render_times(assigns) do
    ~H"""
    <%= for {t, i} <- Enum.with_index(Enum.take(@times, 3)) do %>
      <span>{StreamHTML.format_start_time(t)}</span>
      <span :if={i < min(length(@times), 3) - 1}>➜</span>
    <% end %>

    <span :if={length(@times) > 3}>➜ ...</span>
    """
  end

  defp render_error(assigns) do
    ~H"""
    <span class="text-danger">{String.trim_trailing(@reason, ".")}</span>
    """
  end

  @impl true
  def mount(_params, %{"schedule" => schedule, "timezone" => timezone}, socket) do
    socket =
      socket
      |> assign(:id, "schedule-preview")
      |> assign(:timezone, timezone)
      |> assign(:result, parse(String.trim(schedule), timezone))

    {:ok, socket}
  end

  defp parse(nil, _timezone), do: {:ok, nil}
  defp parse("", _timezone), do: {:ok, nil}

  defp parse(schedule, timezone) do
    with {:ok, expr} <- Crontab.CronExpression.Parser.parse(schedule) do
      now = DateTime.now!(timezone || "Etc/UTC")

      dts =
        expr
        |> Crontab.Scheduler.get_next_run_dates(now)
        |> Elixir.Stream.take(4)
        |> Enum.to_list()

      {:ok, dts}
    end
  rescue
    [RuntimeError, CaseClauseError] -> {:error, "Invalid expression"}
  end

  @impl true
  def handle_event("update", %{"schedule" => schedule}, socket) do
    socket = assign(socket, :result, parse(String.trim(schedule), socket.assigns.timezone))

    {:noreply, socket}
  end
end
