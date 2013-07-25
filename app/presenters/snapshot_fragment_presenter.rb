class SnapshotFragmentPresenter < Draper::Decorator

  delegate :text, :brush

  def to_html
    h.content_tag(:span, text, :class => css_class)
  end

  private

  def css_class
    BrushPresenter.new(brush).to_css_class
  end

end
