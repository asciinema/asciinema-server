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
      h.avatar_image_tag(model)
    end
  end

end
