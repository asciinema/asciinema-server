if CFG['AIRBRAKE_API_KEY']
  require 'airbrake'

  Airbrake.configure do |config|
    config.api_key     = CFG['AIRBRAKE_API_KEY']
    config.host        = CFG['AIRBRAKE_HOST']
    config.port        = 80
    config.secure      = config.port == 443

    envs = ['development', 'bugfix']
    config.development_environments = envs
  end
end
