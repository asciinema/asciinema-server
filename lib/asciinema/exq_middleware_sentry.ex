defmodule Asciinema.Exq.Middleware.Sentry do
  @behaviour Exq.Middleware.Behaviour

  def before_work(pipeline) do
    pipeline
  end

  def after_processed_work(pipeline) do
    pipeline
  end

  def after_failed_work(pipeline) do
    {exception, stacktrace} = pipeline.assigns.error
    Sentry.capture_exception(exception, stacktrace: stacktrace, extra: Poison.decode!(pipeline.assigns.job_serialized))
    pipeline
  end
end
