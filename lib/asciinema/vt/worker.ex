defmodule Asciinema.Vt.Worker do
  use GenServer

  @vt_script_path "vt/main.js"

  # Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def new(pid, width, height) do
    GenServer.cast(pid, {:new, width, height})
  end

  def feed(pid, data) do
    GenServer.cast(pid, {:feed, data})
  end

  def dump_screen(pid, timeout) do
    GenServer.call(pid, :dump_screen, timeout)
  end

  # Server callbacks

  def init(_) do
    path = System.find_executable("node")
    port = Port.open({:spawn_executable, path}, [:binary, args: [@vt_script_path]])
    {:ok, port}
  end

  def handle_call(:dump_screen, _from, port) do
    send_cmd(port, "dump-screen")

    case read_stdout_line(port) do
      {:ok, line} ->
        result = line |> Poison.decode! |> Map.get("result")
        {:reply, {:ok, result}, port}

      {:error, reason} ->
        {:reply, {:error, reason}, port}
    end
  end

  defp read_stdout_line(port) do
    read_stdout_line(port, "")
  end

  defp read_stdout_line(port, line) do
    receive do
      {^port, {:data, data}} ->
        if String.ends_with?(data, "\n") do
          {:ok, line <> String.trim_trailing(data)}
        else
          read_stdout_line(port, line <> data)
        end
    end
  end

  def handle_cast({:new, width, height}, port) do
    send_cmd(port, "new", %{width: width, height: height})
    {:noreply, port}
  end
  def handle_cast({:feed, data}, port) do
    send_cmd(port, "feed-str", %{str: data})
    {:noreply, port}
  end

  defp send_cmd(port, cmd, data \\ %{}) do
    json = data |> Map.put(:cmd, cmd) |> Poison.encode!
    true = Port.command(port, "#{json}\n")
  end
end
