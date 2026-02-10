defmodule AsciinemaWeb.Pagination do
  use Phoenix.Component

  @distance 5

  attr :page, Scrivener.Page, required: true
  attr :params, :list, default: []

  def pagination_links(%{page: %{total_pages: total_pages}} = assigns) when total_pages <= 1 do
    ~H""
  end

  def pagination_links(assigns) do
    %{page: page, params: params} = assigns

    assigns =
      assign(assigns,
        items: build_items(page.page_number, page.total_pages),
        params: params
      )

    ~H"""
    <nav class="pagination">
      <.page_item :for={item <- @items} item={item} params={@params} />
    </nav>
    """
  end

  defp build_items(current, total) do
    first..last//_ = page_range(current, total)
    prev = if current > 1, do: [{:prev, current - 1}], else: []
    next = if current < total, do: [{:next, current + 1}], else: []

    prev ++ build_items(1, total, current, first, last) ++ next
  end

  # Past end
  defp build_items(page, total, _, _, _) when page > total, do: []

  # Page 1, outside the visible range — always shown
  defp build_items(1, total, current, first, last) when first > 1 do
    [{:page, 1} | build_items(2, total, current, first, last)]
  end

  # Gap before range — single ellipsis, jump to range start
  defp build_items(page, total, current, first, last) when page < first do
    [:ellipsis | build_items(first, total, current, first, last)]
  end

  # Pages inside the visible range
  defp build_items(page, total, current, first, last) when page <= last do
    [{:page, page, page == current} | build_items(page + 1, total, current, first, last)]
  end

  # Gap after range — single ellipsis, jump to last page
  defp build_items(page, total, current, first, last) when page < total do
    [:ellipsis | build_items(total, total, current, first, last)]
  end

  # Last page, outside the visible range — always shown
  defp build_items(total, total, _, _, _) do
    [{:page, total}]
  end

  defp page_range(current, total) do
    first = max(1, current - @distance)
    last = min(total, current + @distance)

    first..last
  end

  defp page_item(%{item: {:prev, page}} = assigns) do
    assigns = assign(assigns, :page, page)

    ~H"""
    <a href={page_href(@page, @params)} rel="prev">&lt;&lt;</a>
    """
  end

  defp page_item(%{item: {:next, page}} = assigns) do
    assigns = assign(assigns, :page, page)

    ~H"""
    <a href={page_href(@page, @params)} rel="next">&gt;&gt;</a>
    """
  end

  defp page_item(%{item: {:page, page, true}} = assigns) do
    assigns = assign(assigns, :page, page)

    ~H"""
    <a class="active">{@page}</a>
    """
  end

  defp page_item(%{item: {:page, page, false}} = assigns) do
    assigns = assign(assigns, :page, page)

    ~H"""
    <a href={page_href(@page, @params)}>{@page}</a>
    """
  end

  defp page_item(%{item: {:page, page}} = assigns) do
    assigns = assign(assigns, :page, page)

    ~H"""
    <a href={page_href(@page, @params)}>{@page}</a>
    """
  end

  defp page_item(%{item: :ellipsis} = assigns) do
    ~H"""
    <span class="ellipsis">&hellip;</span>
    """
  end

  defp page_href(1, params), do: "?" <> URI.encode_query(params)

  defp page_href(page, params), do: "?" <> URI.encode_query([page: page] ++ params)
end
