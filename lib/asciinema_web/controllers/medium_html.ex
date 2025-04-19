defmodule AsciinemaWeb.MediumHTML do
  use AsciinemaWeb, :html

  embed_templates "medium_html/*"

  defp segments(medium) do
    [os(medium), term(medium), shell(medium)]
    |> Enum.filter(& &1)
    |> Enum.intersperse(" ◆ ")
  end

  defp os(medium) do
    os_from_user_agent(medium.user_agent) || os_from_uname(medium)
  end

  @doc """
  iex> os_from_user_agent(nil)
  nil

  iex> os_from_user_agent("foo")
  nil

  iex> os_from_user_agent("asciinema/99.9.9 target/x99_64-unknown-lol-bye")
  nil

  iex> os_from_user_agent("asciinema/3.0.0-rc.3 target/x86_64-unknown-linux-gnu")
  "GNU/Linux"

  iex> os_from_user_agent("asciinema/2.4.0 CPython/3.11.6 Linux/6.1.68-x86_64-with-glibc2.38")
  "GNU/Linux"

  iex> os_from_user_agent("asciinema/2.4.0 CPython/3.13.2 macOS/14.6.1-arm64-arm-64bit-Mach-O")
  "macOS"

  iex> os_from_user_agent("asciinema/2.4.0 CPython/3.12.3 Linux/5.15.167.4-microsoft-standard-WSL2-x86_64-with-glibc2.39")
  "WSL2"

  iex> os_from_user_agent("asciinema/3.0.0-rc.3 target/aarch64-apple-darwin")
  "macOS"

  iex> os_from_user_agent("asciinema/2.4.0 CPython/3.11.11 FreeBSD/14.2-RELEASE-p1-amd64-64bit-ELF")
  "FreeBSD"

  iex> os_from_user_agent("asciinema/2.4.0 CPython/3.12.9 OpenBSD/7.7-amd64-64bit-ELF")
  "OpenBSD"
  """
  def os_from_user_agent(nil), do: nil

  def os_from_user_agent(user_agent) do
    cond do
      user_agent =~ ~r/WSL2/ -> "WSL2"
      user_agent =~ ~r/linux/i -> "GNU/Linux"
      user_agent =~ ~r/macos|darwin/i -> "macOS"
      user_agent =~ ~r/freebsd/i -> "FreeBSD"
      user_agent =~ ~r/openbsd/i -> "OpenBSD"
      true -> nil
    end
  end

  defp os_from_uname(medium) do
    if uname = Map.get(medium, :uname) do
      cond do
        uname =~ ~r/Linux/i -> "GNU/Linux"
        uname =~ ~r/Darwin/i -> "macOS"
        true -> uname |> String.split(~r/[\s-]/) |> List.first()
      end
    end
  end

  defp shell(medium) do
    if medium.shell do
      Path.basename("#{medium.shell}")
    end
  end

  defp term(medium) do
    case medium.term_version do
      nil ->
        medium.term_type

      version ->
        {medium.term_type, version}
    end
  end
end
