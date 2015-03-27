class AsciicastPagePresenter

  attr_reader :asciicast, :current_user, :policy, :playback_options

  def self.build(asciicast, current_user, playback_options)
    decorated_asciicast = asciicast.decorate
    policy = Pundit.policy(current_user, asciicast)

    playback_options = {
      'theme' =>  decorated_asciicast.theme_name
    }.merge(playback_options)

    new(decorated_asciicast, current_user, policy,
        PlaybackOptions.new(playback_options))
  end

  def initialize(asciicast, current_user, policy, playback_options)
    @asciicast        = asciicast
    @current_user     = current_user
    @policy           = policy
    @playback_options = playback_options
  end

  def title
    asciicast_title
  end

  def asciicast_title
    asciicast.title
  end

  def author_img_link
    asciicast.author_img_link
  end

  def author_link
    asciicast.author_link
  end

  def asciicast_created_at
    asciicast.created_at
  end

  def asciicast_env_details
    "#{asciicast.os} / #{asciicast.shell} / #{asciicast.terminal_type}"
  end

  def views_count
    asciicast.views_count
  end

  def embed_script(routes)
    src = routes.asciicast_url(asciicast, format: :js)
    id = "asciicast-#{asciicast.id}"
    %(<script type="text/javascript" src="#{src}" id="#{id}" async></script>)
  end

  def embed_html_link(routes)
    img_src = routes.asciicast_url(asciicast, format: :png)
    url = routes.asciicast_url(asciicast)
    %(<a href="#{url}"><img src="#{img_src}"/></a>)
  end

  def embed_markdown_link(routes)
    img_src = routes.asciicast_url(asciicast, format: :png)
    url = routes.asciicast_url(asciicast)
    "[![alt](#{img_src})](#{url})"
  end

  def show_admin_dropdown?
    [show_edit_link?,
     show_delete_link?,
     show_set_featured_link?,
     show_unset_featured_link?].any?
  end

  def show_edit_link?
    policy.update?
  end

  def show_delete_link?
    policy.destroy?
  end

  def show_set_featured_link?
    !asciicast.featured? && policy.feature?
  end

  def show_unset_featured_link?
    asciicast.featured? && policy.unfeature?
  end

  def show_description?
    asciicast.description.present?
  end

  def description
    asciicast.description
  end

  def show_other_asciicasts_by_author?
    author.asciicast_count > 1
  end

  def other_asciicasts_by_author
    author.asciicasts_excluding(asciicast, 3).decorate
  end

  private

  def author
    asciicast.user
  end

end
