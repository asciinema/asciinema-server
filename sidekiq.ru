require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { size: 1, namespace: 'exq' }
end

require 'sidekiq/web'
run Sidekiq::Web
