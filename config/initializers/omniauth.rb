Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, CFG['TWITTER_CONSUMER_KEY'], CFG['TWITTER_CONSUMER_SECRET'], :client_options => { :ssl => { :ca_path => "/etc/ssl/certs" } }
  provider :github, CFG['GITHUB_CONSUMER_KEY'], CFG['GITHUB_CONSUMER_SECRET'], :client_options => { :ssl => { :ca_path => "/etc/ssl/certs" } }
  provider :browser_id
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
