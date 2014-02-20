class AuthCookieStrategy < ::Warden::Strategies::Base

  def valid?
    auth_token.present?
  end

  def authenticate!
    user = User.where(auth_token: auth_token).first
    user && success!(user)
  end

  private

  def auth_token
    request.cookies['auth_token']
  end

end

Warden::Strategies.add(:auth_cookie, AuthCookieStrategy)
