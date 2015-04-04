module WardenAuthentication

  private

  def ensure_authenticated!
    warden.authenticate!(scope: warden_scope) unless warden.authenticated?(warden_scope)
  end

  def current_user
    warden.authenticate(scope: warden_scope) unless warden.authenticated?(warden_scope)
    warden.user(warden_scope)
  end

  def current_user=(user)
    if user
      warden.set_user(user, scope: warden_scope)
      cookies[:auth_token] =
        { value: user.auth_token, expires: 1.year.from_now }
    else
      warden.logout(warden_scope)
      cookies.delete(:auth_token)
    end
  end

  def warden
    request.env['warden']
  end

end
