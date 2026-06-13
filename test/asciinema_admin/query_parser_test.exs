defmodule AsciinemaAdmin.QueryParserTest do
  use ExUnit.Case, async: true

  alias AsciinemaAdmin.QueryParser

  test "normalizes bare terms before sorted structured tokens" do
    parsed = QueryParser.parse(:recordings, "visibility:PUBLIC foo featured:true bar")

    assert parsed.errors == []
    assert parsed.normalized_filter == "foo bar featured:yes visibility:public"
    assert {:title, {:search, "foo bar"}} in parsed.filters
    assert {:visibility, :public} in parsed.filters
    assert {:featured, true} in parsed.filters
  end

  test "rejects duplicate singleton tokens" do
    parsed = QueryParser.parse(:recordings, "featured:yes featured:no")

    assert parsed.errors == ["Duplicate token: featured"]
  end

  test "maps recording archive token to archive mode" do
    yes = QueryParser.parse(:recordings, "archived:yes")
    no = QueryParser.parse(:recordings, "archived:no")
    default = QueryParser.parse(:recordings, "")

    assert yes.archived == :only
    assert no.archived == :exclude
    assert default.archived == :include
  end

  test "parses stream started:never and scheduled bool" do
    parsed = QueryParser.parse(:streams, "started:never scheduled:true")

    assert parsed.errors == []
    assert {:last_started_at, :never} in parsed.filters
    assert {:scheduled, true} in parsed.filters
    assert parsed.normalized_filter == "scheduled:yes started:never"
  end

  test "parses user admin bool filter" do
    parsed = QueryParser.parse(:users, "admin:yes")
    assert parsed.errors == []
    assert {:admin, true} in parsed.filters
    assert parsed.normalized_filter == "admin:yes"

    parsed = QueryParser.parse(:users, "admin:no")
    assert {:admin, false} in parsed.filters
  end

  test "parses user identity search and count range" do
    parsed = QueryParser.parse(:users, "alice streams:0..2")

    assert parsed.errors == []
    assert {:identity, {:search, "alice"}} in parsed.filters
    assert {:stream_count, {:between, 0, 2}} in parsed.filters
  end

  test "parses stream recordings count filter" do
    parsed = QueryParser.parse(:streams, "recordings:>0")

    assert parsed.errors == []
    assert {:recording_count, {:gt, 0}} in parsed.filters
    assert parsed.normalized_filter == "recordings:>0"

    parsed = QueryParser.parse(:streams, "recordings:0")
    assert parsed.errors == []
    assert {:recording_count, {:eq, 0}} in parsed.filters
  end

  test "parses token exact-match filter for recordings and streams" do
    parsed = QueryParser.parse(:recordings, "token:abc123XYZ")
    assert parsed.errors == []
    assert {:token, "abc123XYZ"} in parsed.filters
    assert parsed.normalized_filter == "token:abc123XYZ"

    parsed = QueryParser.parse(:streams, "token:abc123XYZ")
    assert parsed.errors == []
    assert {:token, "abc123XYZ"} in parsed.filters
  end

  test "date ranges include complete UTC end day" do
    parsed = QueryParser.parse(:recordings, "created:2026-01-01..2026-01-02")

    assert {:created_at, {:between, ~U[2026-01-01 00:00:00Z], ~U[2026-01-02 23:59:59Z]}} in parsed.filters
  end

  test "rejects invalid structured values" do
    parsed = QueryParser.parse(:streams, "visibility:publik current-viewers:abc")

    assert "Invalid visibility \"publik\"; expected public, unlisted, or private" in parsed.errors
    assert "Invalid current-viewers \"abc\": expected a non-negative integer" in parsed.errors
  end

  test "parses a plain numeric value as an equality filter" do
    parsed = QueryParser.parse(:users, "recordings:0 streams:5")

    assert parsed.errors == []
    assert {:recording_count, {:eq, 0}} in parsed.filters
    assert {:stream_count, {:eq, 5}} in parsed.filters
  end

  test "supports plain equality for duration and size" do
    parsed = QueryParser.parse(:recordings, "duration:10m size:100mb views:0")

    assert parsed.errors == []
    assert {:duration, {:eq, 600}} in parsed.filters
    assert {:compressed_size, {:eq, 104_857_600}} in parsed.filters
    assert {:views, {:eq, 0}} in parsed.filters
  end

  test "parses the seconds duration unit" do
    eq = QueryParser.parse(:recordings, "duration:10s")
    assert eq.errors == []
    assert {:duration, {:eq, 10}} in eq.filters

    gt = QueryParser.parse(:recordings, "duration:>30s")
    assert gt.errors == []
    assert {:duration, {:gt, 30}} in gt.filters

    range = QueryParser.parse(:recordings, "duration:5s..1m")
    assert range.errors == []
    assert {:duration, {:between, 5, 60}} in range.filters
  end

  test "rejects malformed comparison operators" do
    parsed = QueryParser.parse(:recordings, "views:>>10 duration:<<10m created:=>2026-01-01")

    assert "Invalid views \">>10\": expected a non-negative integer" in parsed.errors
    assert "Invalid duration \"<<10m\": use a unit such as 10s, 10m, or 1h" in parsed.errors

    assert "Invalid created \"=>2026-01-01\": expected today, YYYY-MM-DD, or a window like 30d" in parsed.errors
  end
end
