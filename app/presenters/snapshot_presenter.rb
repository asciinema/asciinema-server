class SnapshotPresenter < Draper::Decorator

  delegate :lines

  def to_html
    h.content_tag(:pre, line_strings.join.html_safe, :class => 'thumbnail')
  end

  private

  def line_strings
    lines.map { |line| line_string(line) }
  end

  def line_string(line)
    SnapshotLinePresenter.new(line).to_html
  end

end
