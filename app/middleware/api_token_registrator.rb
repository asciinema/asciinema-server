class ApiTokenRegistrator

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    auth = Rack::Auth::Basic::Request.new(env)

    if request.post? && request.path == '/api/asciicasts'
      if auth.provided? && auth.basic? && auth.credentials
        ensure_user_with_token(*auth.credentials)
      end
    end

    @app.call(env)

  rescue ActiveRecord::RecordInvalid
    [401, { 'Content-Type' => 'text/plain' }, 'Invalid token']
  end

  private

  def ensure_user_with_token(username, token)
    unless ApiToken.where(token: token).exists?
      ApiToken.create_with_tmp_user!(token, username)
    end
  end

end
