class AsciicastListPresenter

  DEFAULT_CATEGORY = :all
  DEFAULT_ORDER    = :recency
  PER_PAGE         = 12

  attr_reader :category, :order, :page, :per_page

  def self.build(category, order, page = nil, per_page = nil)
    new(
      (category || DEFAULT_CATEGORY).to_sym,
      (order    || DEFAULT_ORDER).to_sym,
      page      || 1,
      per_page  || PER_PAGE
    )
  end

  def initialize(category, order, page, per_page)
    @category = category
    @order    = order
    @page     = page
    @per_page = per_page
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
