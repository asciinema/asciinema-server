defmodule Asciinema.Streaming.Parser do
  # The complete interface to producer-side message parsing; callers hold an
  # opaque parser value. now_us keeps parsers pure - only the raw parser uses
  # it, to stamp event times.

  alias Asciinema.Streaming.Parser

  @callback name() :: binary
  @callback init() :: term
  @callback parse(frame :: {:text | :binary, binary}, state :: term, now_us :: integer) ::
              {:ok, [{atom, term}], term} | {:error, term}
  @callback supported_commands() :: [atom]

  defstruct [:impl, :state]

  @protocols %{
    "raw" => Parser.Raw,
    "v1.alis" => Parser.AlisV1,
    "v2.asciicast" => Parser.AsciicastV2,
    "v3.asciicast" => Parser.AsciicastV3
  }

  @doc "Returns a parser for one of the known protocol names."
  def new(protocol) do
    impl = Map.fetch!(@protocols, protocol)

    %__MODULE__{impl: impl, state: impl.init()}
  end

  @doc "Detects the protocol from the first frame of a connection."
  def detect({:binary, "ALiS\x01"}), do: "v1.alis"
  def detect({:binary, _}), do: "raw"

  def detect({:text, header}) do
    case Jason.decode(header) do
      {:ok, %{"version" => 2}} -> "v2.asciicast"
      {:ok, %{"version" => 3}} -> "v3.asciicast"
      _otherwise -> "raw"
    end
  end

  def name(%__MODULE__{impl: impl}), do: impl.name()

  def supports?(%__MODULE__{impl: impl}, command), do: command in impl.supported_commands()

  def parse(%__MODULE__{impl: impl, state: state} = parser, frame, now_us) do
    with {:ok, commands, new_state} <- impl.parse(frame, state, now_us) do
      {:ok, commands, %{parser | state: new_state}}
    end
  end
end
