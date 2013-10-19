class UserDecorator < ApplicationDecorator

  def asciicasts_count
    model.asciicasts.count
  end

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
    model.avatar_url || gravatar_url
  end

  private

  def gravatar_url
    hash = Digest::MD5.hexdigest(model.email.to_s.downcase)
    "http://gravatar.com/avatar/#{hash}?s=64"
  end

end
