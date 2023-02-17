defmodule Asciinema.ObanErrorReporter do
  def configure do
    :telemetry.attach_many(
      "oban-errors",
      [[:oban, :job, :exception], [:oban, :circuit, :trip]],
      &__MODULE__.handle_event/4,
      %{}
    )
  end

  def handle_event([:oban, :job, :exception], measure, %{job: job} = meta, _) do
    extra =
      job
      |> Map.take([:id, :args, :meta, :queue, :worker])
      |> Map.merge(measure)

    Sentry.capture_exception(meta.error, stacktrace: meta.stacktrace, extra: extra)
  end

  def handle_event([:oban, :circuit, :trip], _measure, meta, _) do
    Sentry.capture_exception(meta.error, stacktrace: meta.stacktrace, extra: meta)
  end
end
