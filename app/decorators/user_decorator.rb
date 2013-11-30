class UserDecorator < ApplicationDecorator

  def link(options = {})
    text = block_given? ? yield : nickname
    h.link_to text, h.profile_path(model), :title => options[:title] || nickname
  end

  def img_link(options = {})
    link(options) do
      h.avatar_image_tag(self)
    end
  end

  def avatar_url
    gravatar_url || model.avatar_url || h.default_avatar_filename
  end

  def fullname_and_nickname
    if model.name.present?
      "#{model.name} (#{model.nickname})"
    else
      model.nickname
    end
  end

  private

  def gravatar_url
    return unless email.present?

    hash = Digest::MD5.hexdigest(model.email.to_s.downcase)
    "//gravatar.com/avatar/#{hash}?s=128"
  end

end
