module AvatarHelper

  def avatar_image_tag
    h.image_tag avatar_url, alt: (model.username || model.temporary_username), class: 'avatar'
  end

  private

  def avatar_url
    gravatar_url || model.avatar_url || default_avatar_filename
  end

  def gravatar_url
    return unless model.email.present?

    hash = Digest::MD5.hexdigest(model.email.to_s.downcase)
    "//gravatar.com/avatar/#{hash}?s=128"
  end

  def default_avatar_filename
    h.image_path "default_avatar.png"
  end

end
