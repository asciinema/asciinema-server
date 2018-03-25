defmodule Asciinema.SshServer do
  require Logger

  def child_spec(_) do
    Supervisor.Spec.worker(__MODULE__, [])
  end

  def start_link do
    if port = c(:port) do
      Logger.info "starting sshd daemon on port #{port}"

      key_dir = c(:key_dir, Application.app_dir(:asciinema, "priv/sshd"))
      key_dir = String.to_charlist(key_dir)

      opts = [subsystems: [],
              user_dir: key_dir,
              system_dir: key_dir,
              user_passwords: [],
              parallel_login: true,
              max_sessions: 50,
              id_string: :random,
              # idle_time: ?,
              auth_methods: String.to_charlist("publickey"),
              ssh_cli: {Asciinema.SshServer.Cli, []},
              negotiation_timeout: 1000,
              key_cb: Asciinema.SshServer.KeyApi]

      with {:ok, pid} <- :ssh.daemon(port, opts) do
        Process.link(pid)
        {:ok, pid}
      end
    else
      Logger.info "sshd port not set in configuration, not starting ssh daemon"
      :ignore
    end
  end

  defp c(key, default \\ nil) do
    Keyword.get(Application.get_env(:asciinema, :sshd, []), key, default)
  end

  defmodule KeyApi do
    @behaviour :ssh_server_key_api

    @impl true
    def host_key(algorithm, daemon_opts) do
      :ssh_file.host_key(algorithm, daemon_opts)
    end

    @impl true
    def is_auth_key({:RSAPublicKey, _key, _}, _username, _daemon_opts) do
      # TODO lookup given key in database
      false
    end
  end

  defmodule Cli do
    def init(_) do
      {:ok, []}
    end

    def handle_msg(_, state) do
      {:ok, state}
    end

    def handle_ssh_msg({_, conn, {:pty, channel_id, want_reply, _}}, state) do
      username = get_username(conn)
      Logger.info "ssh: denying pty for user #{username}"
      deny_shell_access(conn, channel_id, want_reply, state)
    end

    def handle_ssh_msg({_, conn, {:shell, channel_id, want_reply}}, state) do
      username = get_username(conn)
      Logger.info "ssh: denying shell for user #{username}"
      deny_shell_access(conn, channel_id, want_reply, state)
    end

    def handle_ssh_msg({_, conn, {:exec, channel_id, want_reply, cmd}}, state) do
      username = get_username(conn)
      Logger.info "ssh: handling exec for user #{username}: #{cmd}"
      :ssh_connection.reply_request(conn, want_reply, :success, channel_id)
      # TODO check if cmd is "login <token>" and broadcast to user's auth channel
      {:stop, channel_id, state}
    end

    def handle_ssh_msg({_, _, cmd}, state) do
      Logger.info "ssh: ignoring '#{elem(cmd, 0)}' message"
      {:ok, state}
    end

    defp deny_shell_access(conn, channel_id, want_reply, state) do
      username = get_username(conn)
      :ssh_connection.reply_request(conn, want_reply, :success, channel_id)
      :ssh_connection.send(conn, channel_id, "Hi #{username}! You've successfully authenticated, but asciinema does not provide shell access.\n\r")
      {:stop, channel_id, state}
    end

    defp get_username(conn) do
      [user: username] = :ssh_connection_handler.connection_info(conn, [:user])
      List.to_string(username)
    end
  end
end
