class AsciicastList

  attr_reader :category, :order, :repository

  def initialize(category, order, repository = Asciicast)
    @category   = (category || :all).to_sym
    @order      = (order    || :recency).to_sym
    @repository = repository
  end

  def items
    repository.for_category_ordered(category, order)
  end

end
