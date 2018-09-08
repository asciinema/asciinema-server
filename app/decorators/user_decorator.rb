class UserDecorator < ApplicationDecorator
  include AvatarHelper

  def display_name
    model.username || model.temporary_username || "user:#{id}"
  end

  def link
    wrap_with_link(display_name)
  end

  def img_link
    wrap_with_link(avatar_image_tag)
  end

  def theme
    model.theme || Theme.default
  end

  def url
    h.profile_path(model)
  end

  private

  def wrap_with_link(html)
    if id
      h.link_to html, h.profile_path(model), title: display_name
    else
      html
    end
  end

end
