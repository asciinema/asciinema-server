class AsciicastListDecorator < ApplicationDecorator

  PER_PAGE = 12

  attr_reader :page, :per_page

  delegate_all

  def initialize(model, page, per_page = nil)
    super(model)
    @page = page
    @per_page = per_page || PER_PAGE
  end

  def category_name
    "#{category.to_s.capitalize} asciicasts"
  end

  def items
    PaginatingDecorator.new(model.items.paginate(page, per_page))
  end

end
