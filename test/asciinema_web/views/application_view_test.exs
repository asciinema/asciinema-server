defmodule AsciinemaWeb.ApplicationViewTest do
  use ExUnit.Case, async: true

  import AsciinemaWeb.ApplicationView, only: [relative_time: 1]

  describe "relative_time/1" do
    test "past times" do
      assert relative_time(shift(-5)) == "just now"
      assert relative_time(shift(-90)) == "1 minute ago"
      assert relative_time(shift(-2 * 3_600 - 60)) == "2 hours ago"
      assert relative_time(shift(-3 * 86_400 - 60)) == "3 days ago"
      assert relative_time(shift(-45 * 86_400)) == "1 month ago"
      assert relative_time(shift(-359 * 86_400)) == "11 months ago"
      assert relative_time(shift(-362 * 86_400)) == "1 year ago"
      assert relative_time(shift(-800 * 86_400)) == "2 years ago"
    end

    test "future times" do
      assert relative_time(shift(30)) == "in a moment"
      assert relative_time(shift(2 * 3_600 + 60)) == "in 2 hours"
      assert relative_time(shift(3 * 86_400 + 60)) == "in 3 days"
    end
  end

  defp shift(seconds), do: DateTime.add(DateTime.utc_now(), seconds)
end
