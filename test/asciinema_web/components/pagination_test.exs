defmodule AsciinemaWeb.PaginationTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]
  import AsciinemaWeb.Pagination

  defp page(page_number, total_pages) do
    %Scrivener.Page{
      page_number: page_number,
      page_size: 10,
      total_entries: total_pages * 10,
      total_pages: total_pages
    }
  end

  defp render(page_number, total_pages, params \\ []) do
    render_component(&pagination_links/1,
      page: page(page_number, total_pages),
      params: params
    )
  end

  describe "pagination_links/1" do
    test "renders empty for single page" do
      html = render(1, 1)

      refute html =~ "<nav"
      refute html =~ "pagination"
    end

    test "renders empty for zero pages" do
      html = render(1, 0)

      refute html =~ "<nav"
    end

    test "two pages, on page 1" do
      html = render(1, 2)

      # no prev link
      refute html =~ "rel=\"prev\""

      # page 1 is active with no href
      assert html =~ "class=\"active\""

      # page 2 is linked
      assert html =~ "href=\"?page=2\""

      # has next link
      assert html =~ "rel=\"next\""
      assert html =~ "&gt;&gt;"
    end

    test "two pages, on page 2" do
      html = render(2, 2)

      # has prev link
      assert html =~ "rel=\"prev\""
      assert html =~ "&lt;&lt;"

      # page 2 is active
      assert html =~ "class=\"active\""

      # no next link
      refute html =~ "rel=\"next\""
    end

    test "many pages, in the middle (page 8 of 20)" do
      html = render(8, 20)

      # has prev and next
      assert html =~ "rel=\"prev\""
      assert html =~ "rel=\"next\""

      # page 1 link present
      assert html =~ "href=\"?\""

      # ellipsis present (rendered as &hellip;)
      assert html =~ "&hellip;"

      # pages in range 3..13 present
      for p <- 3..13 do
        if p == 8 do
          # active page has no href
          assert html =~ "class=\"active\""
        else
          assert html =~ "href=\"?page=#{p}\""
        end
      end

      # page 20 link present
      assert html =~ "href=\"?page=20\""
    end

    test "many pages, at start (page 1 of 20)" do
      html = render(1, 20)

      # no prev
      refute html =~ "rel=\"prev\""

      # has next
      assert html =~ "rel=\"next\""

      # pages 1..6 present
      assert html =~ "class=\"active\""

      for p <- 2..6 do
        assert html =~ "href=\"?page=#{p}\""
      end

      # ellipsis present
      assert html =~ "&hellip;"

      # page 20 link
      assert html =~ "href=\"?page=20\""

      # no duplicate page 1 link (page 1 only appears once as active)
      # count occurrences of ">1<" in the html
      assert length(Regex.scan(~r/>1</, html)) == 1
    end

    test "many pages, at end (page 20 of 20)" do
      html = render(20, 20)

      # has prev
      assert html =~ "rel=\"prev\""

      # no next
      refute html =~ "rel=\"next\""

      # page 1 link
      assert html =~ "href=\"?\""

      # ellipsis present
      assert html =~ "&hellip;"

      # pages 15..19 linked, page 20 active
      for p <- 15..19 do
        assert html =~ "href=\"?page=#{p}\""
      end

      assert html =~ "class=\"active\""

      # no duplicate page 20 (only appears once as active)
      assert length(Regex.scan(~r/>20</, html)) == 1
    end

    test "with params" do
      html = render(2, 3, q: "foo")

      # page 1 href includes param but not page param
      assert html =~ "href=\"?q=foo\""

      # page 3 href includes both page and param
      assert html =~ "href=\"?page=3&amp;q=foo\""
    end

    test "active page has no href" do
      html = render(5, 10)

      # extract the active page item
      [active] = Regex.scan(~r/<a class="active"[^>]*>/, html)

      refute hd(active) =~ "href="
    end

    test "page 1 href omits page param" do
      html = render(3, 5)

      # page 1 link should be just "?" with no page param
      assert html =~ "href=\"?\""
      refute html =~ "href=\"?page=1\""
    end

    test "page 1 href with params omits page param" do
      html = render(3, 5, q: "bar")

      assert html =~ "href=\"?q=bar\""
      refute html =~ "page=1"
    end
  end
end
