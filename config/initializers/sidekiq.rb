Sidekiq.configure_server do |config|
  config.redis = { namespace: 'exq' }
end

Sidekiq.configure_client do |config|
  config.redis = { namespace: 'exq' }
end
