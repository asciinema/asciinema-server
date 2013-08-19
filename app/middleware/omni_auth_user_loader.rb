class OmniAuthUserLoader

  def initialize(app)
    @app = app
  end

  def call(env)
    omniauth = env['omniauth.auth']

    if omniauth
      env['asciiio.user'] = find_user(omniauth) || build_user(omniauth)
    end

    @app.call(env)
  end

  private

  def find_user(omniauth)
    User.where(:provider => omniauth['provider'], :uid => omniauth['uid'].to_s).first
  end

  def build_user(omniauth)
    user = User.new
    user.provider   = omniauth['provider']
    user.uid        = omniauth['uid']
    user.nickname   = omniauth['info']['nickname']
    user.name       = omniauth['info']['name']
    user.avatar_url = OauthHelper.get_avatar_url(omniauth)

    user
  end

end
