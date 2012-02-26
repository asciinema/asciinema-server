Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, CFG.oauth.twitter.consumer_key, CFG.oauth.twitter.consumer_secret
  provider :github, CFG.oauth.github.consumer_key, CFG.oauth.github.consumer_secret
end
