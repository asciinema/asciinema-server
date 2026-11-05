defmodule AsciinemaWeb.ApplicationViewTest do
  use ExUnit.Case, async: true

  import AsciinemaWeb.ApplicationView, only: [relative_time: 1, render_markdown: 1]

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

  describe "render_markdown/1" do
    test "returns nil for missing or blank descriptions" do
      for input <- [nil, "", " \n\t "] do
        assert render_markdown(input) == nil
      end
    end

    test "renders Markdown with strikethrough and smart punctuation" do
      {:safe, html} = render_markdown(~s(**bold** ~~removed~~ "hello" -- ...))

      assert html =~ "<strong>bold</strong>"
      assert html =~ "<del>removed</del>"
      assert html =~ "“hello” – …"
    end

    test "autolinks bare URLs" do
      {:safe, html} = render_markdown("https://asciinema.org")

      assert html =~ ~s(<a href="https://asciinema.org">https://asciinema.org</a>)
    end

    test "renders tables" do
      {:safe, html} = render_markdown("| name |\n| --- |\n| value |")

      assert html =~ "<table>"
      assert html =~ "<th>name</th>"
      assert html =~ "<td>value</td>"
    end

    test "escapes HTML in code blocks" do
      {:safe, html} = render_markdown("```elixir\nIO.puts(\"<script>\")\n```")

      assert html =~ "<pre><code>"
      assert html =~ ~s|IO.puts("&lt;script&gt;")|
      refute html =~ "<script>"
    end

    test "leaves template expressions unevaluated" do
      {:safe, html} = render_markdown("<%= 1 + 1 %> {1 + 1}")

      assert html =~ "&lt;%= 1 + 1 %&gt;"
      assert html =~ "{1 + 1}"
    end

    test "preserves allowed embedded HTML while stripping unsafe tags and attributes" do
      {:safe, html} =
        render_markdown("""
        Use <strong>bold</strong> and <em>emphasis</em>.

        <script>alert(1)</script>

        <img src="https://example.org/a.png" onerror="alert(1)">
        """)

      assert html =~ "<strong>bold</strong>"
      assert html =~ "<em>emphasis</em>"
      assert html =~ ~s(src="https://example.org/a.png")
      refute html =~ "<script"
      refute html =~ "onerror"
    end

    test "removes unsafe URLs from Markdown and embedded HTML links" do
      for input <- [
            "[click](javascript:alert%281%29)",
            ~s|<a href="jav&#x61;script:alert(1)">click</a>|,
            "[click](data:text/html;base64,PHNjcmlwdD4=)"
          ] do
        assert {:safe, html} = render_markdown(input)
        assert html =~ "click"
        refute html =~ "href="
      end
    end
  end

  defp shift(seconds), do: DateTime.add(DateTime.utc_now(), seconds)
end
