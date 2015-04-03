class AuthCookieStrategy < ::Warden::Strategies::Base

  def valid?
    auth_token.present?
  end

  def authenticate!
    user = User.for_auth_token(auth_token)
    user && success!(user)
  end

  private

  def auth_token
    request.cookies['auth_token']
  end

end
