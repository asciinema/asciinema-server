class CellDecorator < ApplicationDecorator

  delegate_all
  delegate :css_class, to: :brush

  def brush
    BrushDecorator.new(model.brush)
  end

end
