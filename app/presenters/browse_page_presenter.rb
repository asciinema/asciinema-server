class BrowsePagePresenter

  DEFAULT_CATEGORY = :public
  DEFAULT_ORDER    = :date
  PER_PAGE         = 12

  attr_reader :scope, :category, :order, :page, :per_page

  def self.build(scope, category, order, page = nil, per_page = nil)
    new(
      scope,
      (category || DEFAULT_CATEGORY).to_sym,
      (order    || DEFAULT_ORDER).to_sym,
      page      || 1,
      per_page  || PER_PAGE
    )
  end

  def initialize(scope, category, order, page, per_page)
    @scope    = scope
    @category = category
    @order    = order
    @page     = page
    @per_page = per_page
  end

  def category_name
    "#{category.to_s.capitalize} asciicasts"
  end

  def items
    @items ||= get_items
  end

  private

  def get_items
    PaginatingDecorator.new(
      scope.for_category_ordered(category, order, page, per_page)
    )
  end

end
