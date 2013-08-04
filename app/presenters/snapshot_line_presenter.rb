class SnapshotLinePresenter < Draper::Decorator

  delegate :map

  def to_html
    h.content_tag(:span, fragment_strings.html_safe, :class => 'line')
  end

  private

  def fragment_strings
    map { |fragment| fragment_string(fragment) }.join
  end

  def fragment_string(fragment)
    SnapshotFragmentPresenter.new(fragment).to_html
  end

end
