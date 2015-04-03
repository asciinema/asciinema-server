class ApiTokenStrategy < ::Warden::Strategies::Base

  def valid?
    auth.provided? && auth.basic? && auth.credentials
  end

  def authenticate!
    user = User.for_api_token(auth.credentials.last)
    user.nil? ? fail!("Invalid auth token") : success!(user)
  end

  def store?
    false
  end

  private

  def auth
    @auth ||= Rack::Auth::Basic::Request.new(env)
  end

end

Warden::Strategies.add(:api_token, ApiTokenStrategy)
