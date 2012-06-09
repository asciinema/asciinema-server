Airbrake.configure do |config|
  unless CFG['AIRBRAKE_API_KEY'].blank?
    config.api_key     = CFG['AIRBRAKE_API_KEY']
    config.host        = CFG['AIRBRAKE_HOST']
    config.port        = 80
    config.secure      = config.port == 443
  end

  envs = ['development', 'bugfix']
  envs << Rails.env if CFG['AIRBRAKE_API_KEY'].blank?
  config.development_environments = envs
end
