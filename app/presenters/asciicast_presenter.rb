class AsciicastPresenter

  attr_reader :asciicast, :user

  def initialize(asciicast, user)
    @asciicast = AsciicastDecorator.new(asciicast)
    @user = user
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

  def embed_script(h)
    src = h.asciicast_url(asciicast, format: :js)
    id = "asciicast-#{asciicast.id}"
    %(<script type="text/javascript" src="#{src}" id="#{id}" async></script>)
  end

  def show_admin_dropdown?
    asciicast.managable_by?(user)
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
    asciicasts = author.asciicasts_excluding(asciicast, 3)

    AsciicastDecorator.decorate_collection(asciicasts)
  end

  private

  def author
    asciicast.user
  end

end
