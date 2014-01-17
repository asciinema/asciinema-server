class AsciicastListPresenter

  PER_PAGE = 12

  attr_reader :category, :order, :page, :per_page

  def initialize(category, order, page, per_page = nil)
    @category = (category || :all).to_sym
    @order    = (order    || :recency).to_sym
    @per_page = per_page  || PER_PAGE
    @page     = page      || 1
  end

  def category_name
    "#{category.to_s.capitalize} asciicasts"
  end

  def items
    PaginatingDecorator.new(
      Asciicast.for_category_ordered(category, order, page, per_page)
    )
  end

end
