module AvatarHelper

  def avatar_image_tag
    h.image_tag avatar_url, alt: (model.username || model.temporary_username), class: 'avatar'
  end

  private

  def avatar_url
    username = model.username || model.temporary_username || model.id
    email = model.email || "#{username}@asciinema.org"
    hash = Digest::MD5.hexdigest(email.downcase)
    "//gravatar.com/avatar/#{hash}?s=128&d=retro"
  end

end
