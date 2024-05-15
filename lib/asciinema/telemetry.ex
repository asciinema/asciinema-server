defmodule Asciinema.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    if enabled?() do
      Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
    else
      :ignore
    end
  end

  def init(_arg) do
    children = [{:telemetry_poller, period: 10_000}]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @buckets [5, 10, 25, 50, 100, 250, 500, 1_000, 2_500, 5_000, 10_000]

  def metrics do
    repo_distribution = [
      unit: {:native, :millisecond},
      tags: [:query, :source],
      drop: &is_nil(&1.source),
      reporter_options: [buckets: @buckets]
    ]

    phoenix_distribution = [
      unit: {:native, :millisecond},
      tags: [:plug, :route, :method, :status, :event],
      tag_values: &phoenix_router_dispatch_tag_values/1,
      reporter_options: [buckets: @buckets]
    ]

    oban_distribution = [
      unit: {:native, :millisecond},
      tags: [:queue, :worker, :state],
      tag_values: &oban_job_tag_values/1,
      reporter_options: [buckets: @buckets]
    ]

    oban_counter = [
      tags: [:queue, :worker],
      tag_values: &oban_job_tag_values/1
    ]

    [
      # VM
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io"),

      # Ecto
      distribution("asciinema.repo.query.total_time", repo_distribution),
      distribution("asciinema.repo.query.decode_time", repo_distribution),
      distribution("asciinema.repo.query.query_time", repo_distribution),
      distribution("asciinema.repo.query.idle_time", repo_distribution),
      distribution("asciinema.repo.query.queue_time", repo_distribution),

      # Phoenix
      distribution("phoenix.endpoint.start.system_time", phoenix_distribution),
      distribution("phoenix.endpoint.stop.duration", phoenix_distribution),
      distribution("phoenix.router_dispatch.start.system_time", phoenix_distribution),
      distribution("phoenix.router_dispatch.exception.duration", phoenix_distribution),
      distribution("phoenix.router_dispatch.stop.duration", phoenix_distribution),
      distribution("phoenix.socket_connected.duration", phoenix_distribution),
      distribution("phoenix.channel_join.duration", phoenix_distribution),
      distribution("phoenix.channel_handled_in.duration", phoenix_distribution),

      # Oban
      counter("oban.job.start.count", oban_counter),
      distribution("oban.job.stop.duration", oban_distribution),
      distribution("oban.job.exception.duration", oban_distribution)
    ]
  end

  defp oban_job_tag_values(metadata) do
    worker =
      metadata.job.worker
      |> String.replace(~r/^Asciinema\./, "")
      |> String.replace(".", "")

    %{
      queue: metadata.job.queue,
      worker: worker,
      state: metadata[:state]
    }
  end

  defp phoenix_router_dispatch_tag_values(metadata) do
    metadata
    |> Map.update(:plug, nil, &String.replace(to_string(&1), "Elixir.AsciinemaWeb.", ""))
    |> Map.put(:method, metadata.conn.method)
    |> Map.put(:status, metadata.conn.status)
  end

  defp enabled? do
    Keyword.get(Application.get_env(:asciinema, __MODULE__, []), :enabled, true)
  end
end
