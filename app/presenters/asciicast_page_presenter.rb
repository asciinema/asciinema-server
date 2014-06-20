class AsciicastPagePresenter

  attr_reader :asciicast, :current_user, :playback_options

  def self.build(asciicast, current_user, playback_options)
    new(asciicast.decorate, current_user, PlaybackOptions.new(playback_options))
  end

  def initialize(asciicast, current_user, playback_options)
    @asciicast        = asciicast
    @current_user     = current_user
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

  def oembed_discovery(h)
    url = h.asciicast_url(asciicast)
    href = helpers.url_for(
              :controller => "asciicasts", :action => "oembed", :only_path => false,
              :params => {:url => url, :format => "json"}
            )
    %(<link rel="alternate" type="application/json+oembed"
    href="#{href}" title="#{asciicast.title}">)
  end

  def embed_script(h)
    src = h.asciicast_url(asciicast, format: :js)
    id = "asciicast-#{asciicast.id}"
    %(<script type="text/javascript" src="#{src}" id="#{id}" async></script>)
  end

  def show_admin_dropdown?
    asciicast.managable_by?(current_user)
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

  def helpers
    Rails.application.routes.url_helpers
  end

  def author
    asciicast.user
  end

end
