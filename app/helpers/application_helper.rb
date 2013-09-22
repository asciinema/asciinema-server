module ApplicationHelper
  def page_title
    title = "asciinema"

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

  def indented_text(string, width)
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

  def avatar_image_tag(user, options = {})
    klass = options[:class] || "avatar"
    title = options[:title] || user.try(:nickname)

    avatar = user.try(:avatar_url) || default_avatar_filename
    image_tag avatar, :alt => title, :class => klass
  end

  def default_avatar_filename
    image_path "default_avatar.png"
  end

  def color_check_asciicast_path
    if id = CFG['COLOR_CHECK_CAST_ID']
      asciicast_path(id)
    end
  end
end
