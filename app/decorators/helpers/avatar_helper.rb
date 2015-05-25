module AvatarHelper

  def avatar_image_tag
    h.image_tag avatar_url(model), alt: (model.username || model.temporary_username), class: 'avatar'
  end

  module GravatarURL
    def avatar_url(model)
      username = model.username || model.temporary_username
      email = model.email || "#{username}+#{model.id}@asciinema.org"
      hash = Digest::MD5.hexdigest(email.downcase)
      "//gravatar.com/avatar/#{hash}?s=128&d=retro"
    end
  end

  module TestAvatarURL
    def avatar_url(model)
      h.image_path 'favicon.png'
    end
  end

end
