class MetadataParser

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    auth = Rack::Auth::Basic::Request.new(env)

    if request.post? && request.path == '/api/asciicasts'
      if request.params['asciicast']['meta'] # pre "format 1" client
        meta = JSON.parse(request.params['asciicast']['meta'][:tempfile].read)
        request.params['asciicast']['meta'] = meta

        username, token = meta.delete('username'), meta.delete('user_token')
        if token.present? && !auth.provided? || !auth.basic?
          env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, token)
        end
      end
    end

    @app.call(env)
  end

end
