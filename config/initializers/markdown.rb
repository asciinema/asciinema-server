MKD_SAFE_RENDERER = Redcarpet::Markdown.new(
  Redcarpet::Render::HTML.new(:filter_html => true, :hard_wrap => true),
  :no_intra_emphasis => true,
  :autolink => true
)

MKD_RENDERER = Redcarpet::Markdown.new(
  Redcarpet::Render::HTML.new,
  :no_intra_emphasis => true,
  :autolink => true
)

module MarkdownHandler
  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template)
    compiled_source = erb.call(template)
    "MKD_RENDERER.render(begin;#{compiled_source};end).html_safe"
  end
end

ActionView::Template.register_template_handler :md, MarkdownHandler
