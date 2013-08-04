class SnapshotPresenter < Draper::Decorator

  delegate :map

  def to_html
    h.content_tag(:pre, lines_html.html_safe, :class => 'terminal')
  end

  private

  def lines_html
    map { |line| line_html(line) }.join("\n") + "\n"
  end

  def line_html(line)
    SnapshotLinePresenter.new(line).to_html
  end

end
