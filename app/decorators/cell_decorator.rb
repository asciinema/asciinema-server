class CellDecorator < ApplicationDecorator

  delegate_all

  def css_class
    BrushPresenter.new(brush).to_css_class
  end

end
