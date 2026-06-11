defmodule AsciinemaAdmin.HomeHTML do
  use AsciinemaAdmin, :html

  embed_templates "home_html/*"

  @doc "Sum the counts in a `[{date, count}]` series (e.g. for a 30-day total)."
  def series_total(series), do: Enum.reduce(series, 0, fn {_date, count}, acc -> acc + count end)

  @doc "Sum of the last `n` buckets of a `[{date, count}]` series (1 = today)."
  def series_window(series, n), do: series |> Enum.take(-n) |> series_total()

  @doc """
  A three-window growth strip — today / last 7 days / last 30 days — derived
  entirely from the 30-day daily series, so it adds no queries.
  """
  attr :series, :list, required: true

  def delta_strip(assigns) do
    assigns =
      assign(assigns,
        today: series_window(assigns.series, 1),
        week: series_window(assigns.series, 7),
        month: series_window(assigns.series, 30)
      )

    ~H"""
    <div class="stat-delta">
      <span class="delta-item">+{fmt_int(@today)} <span class="delta-period">today</span></span>
      <span class="delta-item">+{fmt_int(@week)} <span class="delta-period">7d</span></span>
      <span class="delta-item">+{fmt_int(@month)} <span class="delta-period">30d</span></span>
    </div>
    """
  end

  @doc "Insert thousand separators into an integer for display."
  def fmt_int(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.reverse()
  end
end
