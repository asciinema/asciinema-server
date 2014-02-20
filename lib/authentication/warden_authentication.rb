module WardenAuthentication

  private

  def current_user
    warden.authenticate(:auth_cookie) unless warden.authenticated?
    warden.user
  end

  def current_user=(user)
    if user
      warden.set_user(user)
      cookies[:auth_token] =
        { value: user.auth_token, expires: 1.year.from_now }
    else
      warden.logout
      cookies.delete(:auth_token)
    end
  end

  def warden
    request.env['warden']
  end

end
