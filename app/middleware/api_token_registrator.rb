class ApiTokenRegistrator

  def initialize(app)
    @app = app
  end

  def call(env)
    auth = Rack::Auth::Basic::Request.new(env)

    if auth.provided? && auth.basic? && auth.credentials
      ensure_user_with_token(*auth.credentials)
    end

    @app.call(env)
  end

  private

  def ensure_user_with_token(username, token)
    unless ApiToken.where(token: token).exists?
      ApiToken.create_with_tmp_user!(token, username)
    end
  end

end
