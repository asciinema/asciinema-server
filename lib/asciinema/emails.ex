defmodule Asciinema.Emails do
  alias Asciinema.Emails.{Email, Mailer}

  defmodule Job do
    use Oban.Worker, queue: :emails

    @impl Oban.Worker
    def perform(job) do
      case job.args["type"] do
        "signup" ->
          job.args["to"]
          |> Email.signup_email(job.args["url"])
          |> Mailer.deliver_now!()

        "login" ->
          job.args["to"]
          |> Email.login_email(job.args["url"])
          |> Mailer.deliver_now!()
      end

      :ok
    end
  end

  def send_email(type, to, url) do
    Job.new(%{type: type, to: to, url: url})
    |> Oban.insert!()

    :ok
  end

  def send_email(:test, to) do
    to
    |> Email.test_email()
    |> Mailer.deliver_now!()
  end
end
