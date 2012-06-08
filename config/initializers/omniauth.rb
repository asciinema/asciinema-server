Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, CFG.oauth.twitter.consumer_key, CFG.oauth.twitter.consumer_secret, :client_options => { :ssl => { :ca_path => "/etc/ssl/certs" } }
  provider :github, CFG.oauth.github.consumer_key, CFG.oauth.github.consumer_secret, :client_options => { :ssl => { :ca_path => "/etc/ssl/certs" } }
end
