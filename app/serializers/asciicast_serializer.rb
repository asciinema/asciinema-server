class AsciicastSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :url, :snapshot, :width, :height

  def id
    object.to_param
  end

  def url
    if v0_url?
      object.stdout_frames_url
    else
      asciicast_path(object, format: :json)
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

  def v0_url?
    !!@options[:v0]
  end

end
