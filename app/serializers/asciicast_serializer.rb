class AsciicastSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :url, :snapshot
  attribute :terminal_columns, key: :width
  attribute :terminal_lines, key: :height

  def id
    object.to_param
  end

  def url
    if playback_options.v0
      object.stdout_frames_url
    else
      object.data_url
    end
  end

  def private?
    object.private?
  end

  def title
    object.title
  end

  def author_display_name
    object.user.display_name
  end

  def author_url
    object.user.url
  end

  def author_avatar_url
    object.user.avatar_url(object.user)
  end

  private

  def playback_options
    @options[:playback_options]
  end

end
