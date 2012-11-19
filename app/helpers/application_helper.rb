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

  def link_to_category(text, url, name)
    opts = {}

    if name == @current_category
      opts[:class] = 'active'
    end

    link_to text, url, opts
  end

  def time_ago_tag(time, options = {})
    options[:class] ||= "timeago"
    content_tag(:abbr, time.to_s, options.merge(:title => time.getutc.iso8601))
  end
end
