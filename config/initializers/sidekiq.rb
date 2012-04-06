SIDEKIQ_URL = 'redis://localhost:6379'
SIDEKIQ_NS = 'asciiio-sidekiq'

Sidekiq.configure_server do |config|
  config.redis = {
    :url => SIDEKIQ_URL,
    :namespace => SIDEKIQ_NS
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    :url => SIDEKIQ_URL,
    :namespace => SIDEKIQ_NS,
    :size => 1
  }
end
