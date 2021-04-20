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
          |> Mailer.deliver_now()

        "login" ->
          job.args["to"]
          |> Email.login_email(job.args["url"])
          |> Mailer.deliver_now()
      end

      :ok
    end
  end

  def send_signup_email(to, url) do
    Job.new(%{type: :signup, to: to, url: url})
    |> Oban.insert()
  end

  def send_login_email(to, url) do
    Job.new(%{type: :login, to: to, url: url})
    |> Oban.insert()
  end
end
