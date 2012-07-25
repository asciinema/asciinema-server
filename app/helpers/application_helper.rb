module ApplicationHelper
  def page_title
    title = "ascii.io"

    if @title
      title = "#{@title} - #{title}"
    end

    title
  end

  def twitter_auth_path
    "/auth/twitter"
  end

  def github_auth_path
    "/auth/github"
  end

  def markdown(&block)
    text = capture(&block)
    MKD_RENDERER.render(capture(&block)).html_safe
  end

  def indented(string, width)
    string.lines.map { |l| "#{' ' * width}#{l}" }.join('')
  end

  def category_link(text, url, name)
    opts = {}

    if name == @current_category
      opts[:class] = 'active'
    end

    link_to text, url, opts
  end
end
