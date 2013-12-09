if CFG.airbrake_api_key
  Airbrake.configure do |config|
    config.api_key = CFG.airbrake_api_key
    config.host    = CFG.airbrake_host if CFG.airbrake_host
    config.port    = 80
    config.secure  = config.port == 443
  end
end
