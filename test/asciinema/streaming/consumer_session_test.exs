defmodule Asciinema.Streaming.ConsumerSessionTest do
  use ExUnit.Case, async: true

  alias Asciinema.Streaming.Alis
  alias Asciinema.Streaming.ConsumerSession

  # Exact frame bytes are owned by the Alis.V1 codec tests, so expected
  # frames here are built with the codec.

  @theme %{fg: {1, 1, 1}, bg: {2, 2, 2}, palette: for(i <- 1..8, do: {i, i, i})}

  defp info_data do
    %{last_id: 3, time: 100, term_size: {80, 24}, term_theme: @theme, term_init: "abc"}
  end

  defp initialized do
    {_frame, session} = ConsumerSession.handle_event(ConsumerSession.new(), :info, info_data())

    session
  end

  test "events before init are dropped" do
    session = ConsumerSession.new()

    assert {nil, ^session} =
             ConsumerSession.handle_event(session, :output, %{id: 1, time: 5, text: "x"})
  end

  test "first info produces an init frame and initializes the session" do
    {frame, session} = ConsumerSession.handle_event(ConsumerSession.new(), :info, info_data())

    assert frame ==
             Alis.V1.encode_frame(
               {:init,
                %{
                  last_id: 3,
                  time: 100,
                  term_size: {80, 24},
                  term_theme: @theme,
                  term_init: "abc"
                }}
             )

    assert session.init
    assert session.last_event_time == 100
  end

  test "subsequent info is ignored" do
    session = initialized()

    assert {nil, ^session} = ConsumerSession.handle_event(session, :info, info_data())
  end

  test "reset re-initializes even when already initialized" do
    session = initialized()
    data = %{last_id: 9, time: 500, term_size: {100, 50}}

    {frame, session} = ConsumerSession.handle_event(session, :reset, data)

    assert frame ==
             Alis.V1.encode_frame(
               {:init,
                %{last_id: 9, time: 500, term_size: {100, 50}, term_theme: nil, term_init: nil}}
             )

    assert session.last_event_time == 500
  end

  test "events after init are encoded with relative times" do
    session = initialized()

    {frame, session} =
      ConsumerSession.handle_event(session, :output, %{id: 4, time: 350, text: "hello"})

    assert frame == Alis.V1.encode_frame({:output, %{id: 4, rel_time: 250, text: "hello"}})
    assert session.last_event_time == 350

    {frame, session} =
      ConsumerSession.handle_event(session, :input, %{id: 5, time: 360, text: "x"})

    assert frame == Alis.V1.encode_frame({:input, %{id: 5, rel_time: 10, text: "x"}})

    {frame, session} =
      ConsumerSession.handle_event(session, :resize, %{id: 6, time: 400, term_size: {90, 30}})

    assert frame ==
             Alis.V1.encode_frame({:resize, %{id: 6, rel_time: 40, term_size: {90, 30}}})

    {frame, session} =
      ConsumerSession.handle_event(session, :marker, %{id: 7, time: 400, label: "ch1"})

    assert frame == Alis.V1.encode_frame({:marker, %{id: 7, rel_time: 0, label: "ch1"}})
    assert session.last_event_time == 400
  end

  test "reset forwards term_theme and term_init when present" do
    data = %{last_id: 9, time: 500, term_size: {100, 50}, term_theme: @theme, term_init: "zz"}

    {frame, _session} = ConsumerSession.handle_event(initialized(), :reset, data)

    assert frame ==
             Alis.V1.encode_frame(
               {:init,
                %{
                  last_id: 9,
                  time: 500,
                  term_size: {100, 50},
                  term_theme: @theme,
                  term_init: "zz"
                }}
             )
  end

  test "backwards event times clamp to a zero delta and keep the clock monotonic" do
    session = initialized()

    {frame, session} =
      ConsumerSession.handle_event(session, :output, %{id: 1, time: 90, text: "x"})

    assert frame == Alis.V1.encode_frame({:output, %{id: 1, rel_time: 0, text: "x"}})

    # the clock did not move backwards: the next delta is measured from 100
    {frame, _session} =
      ConsumerSession.handle_event(session, :output, %{id: 2, time: 150, text: "y"})

    assert frame == Alis.V1.encode_frame({:output, %{id: 2, rel_time: 50, text: "y"}})
  end

  test "end produces a bare EOT frame and returns the session to awaiting init" do
    session = initialized()

    {frame, session} = ConsumerSession.handle_event(session, :end, %{})

    assert frame == Alis.V1.encode_frame({:eot, %{}})
    refute session.init

    # events between EOT and the next init are dropped
    assert {nil, ^session} =
             ConsumerSession.handle_event(session, :output, %{id: 8, time: 300, text: "y"})

    # the stream restart re-initializes via reset
    {frame, _session} =
      ConsumerSession.handle_event(session, :reset, %{
        last_id: 9,
        time: 400,
        term_size: {80, 24}
      })

    assert <<1, _rest::binary>> = frame
  end
end
