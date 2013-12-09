Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, CFG.twitter_consumer_key, CFG.twitter_consumer_secret, :client_options => { :ssl => { :ca_path => "/etc/ssl/certs" } }
  provider :github, CFG.github_consumer_key, CFG.github_consumer_secret, :client_options => { :ssl => { :ca_path => "/etc/ssl/certs" } }
  provider :browser_id
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
