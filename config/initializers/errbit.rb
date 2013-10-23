if CFG['AIRBRAKE_API_KEY']
  Airbrake.configure do |config|
    config.api_key = CFG['AIRBRAKE_API_KEY']
    config.host    = CFG['AIRBRAKE_HOST'] if CFG['AIRBRAKE_HOST']
    config.port    = 80
    config.secure  = config.port == 443
  end
end
