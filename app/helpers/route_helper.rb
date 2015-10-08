module RouteHelper

  def profile_path(user)
    if user.username
      public_profile_path(username: user.username)
    else
      unnamed_user_path(user)
    end
  end

  def profile_url(user)
    root_url[0..-2] + profile_path(user)
  end

end
