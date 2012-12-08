class UserDecorator < ApplicationDecorator
  decorates :user

  def nickname
    "~#{user.nickname}"
  end

  def asciicasts_count
    model && model.asciicasts.count
  end

  def avatar_img(options = {})
    klass = options[:class] || "avatar"
    title = options[:title] || user && nickname

    h.image_tag user && user.avatar_url || default_avatar_url,
      :title => title, :alt => title, :class => klass
  end

  def default_avatar_url
    h.image_path "default_avatar.png"
  end

  def avatar_profile_link(options = {})
    options = { :class => '' }.merge(options)

    if user
      h.link_to h.profile_path(user) do
        avatar_img(options)
      end
    else
      avatar_img(options)
    end
  end
end
