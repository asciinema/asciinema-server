if CFG.bugsnag_api_key
  Bugsnag.configure do |config|
    config.api_key = CFG.bugsnag_api_key
  end
end
