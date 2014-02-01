module ApplicationHelper

  class CategoryLinks

    def initialize(current_category, view_context)
      @current_category = current_category
      @view_context = view_context
    end

    def link_to(*args)
      @view_context.link_to_category(@current_category, *args)
    end

  end

  def page_title
    if content_for?(:title)
      "#{content_for(:title)} - Asciinema"
    else
      "Asciinema - Record and share your terminal sessions, the right way"
    end
  end

  def twitter_auth_path
    "/auth/twitter"
  end

  def github_auth_path
    "/auth/github"
  end

  def browser_id_user
    email = current_user && current_user.email || session[:new_user_email]
    email ? "'#{email}'".html_safe : 'null'
  end

  def category_links(current_category, &blk)
    links = CategoryLinks.new(current_category, self)

    content_tag(:ul, class: 'nav nav-pills nav-stacked') do
      blk.call(links)
    end
  end

  def link_to_category(current_category, text, url, name)
    opts = {}

    if name == current_category
      opts[:class] = 'active'
    end

    content_tag(:li, link_to(text, url), opts)
  end

  def time_ago_tag(time, options = {})
    options[:class] ||= "timeago"
    content_tag(:abbr, time.to_s, options.merge(:title => time.getutc.iso8601))
  end

end
