class UserDecorator < ApplicationDecorator
  include AvatarHelper

  def link
    wrap_with_link(nickname)
  end

  def img_link
    wrap_with_link(avatar_image_tag)
  end

  def fullname_and_nickname
    if model.name.present?
      "#{model.name} (#{model.nickname})"
    else
      model.nickname
    end
  end

  private

  def wrap_with_link(html)
    if id
      h.link_to html, h.profile_path(model), title: nickname
    else
      html
    end
  end

end
