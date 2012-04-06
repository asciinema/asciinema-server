MKD_RENDERER = Redcarpet::Markdown.new(
  Redcarpet::Render::HTML.new(:filter_html => true),
  :no_intra_emphasis => true,
  :autolink => true
)
