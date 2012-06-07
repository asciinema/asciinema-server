Airbrake.configure do |config|
  unless CFG.airbrake_api_key.blank?
    config.api_key     = CFG.airbrake_api_key
    config.host        = CFG.airbrake_host
    config.port        = 80
    config.secure      = config.port == 443
  end

  envs = ['development', 'bugfix']
  envs << Rails.env if CFG.airbrake_api_key.blank?
  config.development_environments = envs
end
