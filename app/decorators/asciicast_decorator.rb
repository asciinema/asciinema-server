class AsciicastDecorator < ApplicationDecorator
  decorates_association :user

  THUMBNAIL_WIDTH = 20
  THUMBNAIL_HEIGHT = 10

  def os
    return 'unknown' if uname.blank?

    if uname =~ /Linux/
      'Linux'
    elsif uname =~ /Darwin/
      'OSX'
    else
      uname.split(' ', 2)[0]
    end
  end

  def terminal_type
    model.terminal_type.presence || '?'
  end

  def shell
    File.basename(model.shell.to_s)
  end

  def title
    if model.title.present?
      model.title
    elsif command.present?
      "$ #{command}"
    else
      "##{id}"
    end
  end

  def thumbnail(width = THUMBNAIL_WIDTH, height = THUMBNAIL_HEIGHT)
    if @thumbnail.nil?
      lines = model.snapshot.to_s.split("\n")

      top_lines = lines[0...height]
      top_text = prepare_lines(top_lines, width, height).join("\n")

      bottom_lines = lines.reverse[0...height].reverse
      bottom_text = prepare_lines(bottom_lines, width, height).join("\n")

      if top_text.gsub(/\s+/, '').size > bottom_text.gsub(/\s+/, '').size
        @thumbnail = top_text
      else
        @thumbnail = bottom_text
      end
    end

    @thumbnail
  end

  def description
    if model.description.present?
      text = model.description.to_s
      markdown(text)
    else
      h.content_tag :em, 'No description.'
    end
  end

  def author_link
    if user
      user.link
    else
      author
    end
  end

  def author_img_link
    if user
      user.img_link
    else
      h.avatar_image_tag nil
    end
  end

  def other_by_user
    if user
      AsciicastDecorator.decorate_collection(
        user.asciicasts.where('id <> ?', model.id).limit(3)
      )
    else
      []
    end
  end

  def author
    if user
      user.nickname
    elsif model.username
      "~#{model.username}"
    else
      'anonymous'
    end
  end

  def embed_script
    src = h.asciicast_url(model, :format => :js)
    id = "asciicast-#{model.id}"
    %(<script type="text/javascript" src="#{src}" id="#{id}" async></script>)
  end

  private

  def prepare_lines(lines, width, height)
    (height - lines.size).times { lines << '' }

    lines.map do |line|
      line = line[0...width]
      line << ' ' * (width - line.size)
      line
    end
  end

end
