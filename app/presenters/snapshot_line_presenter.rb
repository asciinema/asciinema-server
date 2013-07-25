class SnapshotLinePresenter < Draper::Decorator

  delegate :fragments

  def to_html
    h.content_tag(:span, fragment_strings.join.html_safe, :class => 'line')
  end

  private

  def fragment_strings
    fragments.map { |fragment| fragment_string(fragment) }
  end

  def fragment_string(fragment)
    SnapshotFragmentPresenter.new(fragment).to_html
  end

end
