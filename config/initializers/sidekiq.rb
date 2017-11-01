Sidekiq.configure_client do |config|
  config.redis = { namespace: 'exq' }
end
