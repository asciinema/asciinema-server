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
          |> deliver()

        "login" ->
          job.args["to"]
          |> Email.login_email(job.args["url"])
          |> deliver()

        "account_deletion" ->
          job.args["to"]
          |> Email.account_deletion_email(job.args["url"])
          |> deliver()
      end

      :ok
    end

    defp deliver(email) do
      with {:permanent_failure, _, _} <- Mailer.deliver_now!(email) do
        {:cancel, :permanent_failure}
      end
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
