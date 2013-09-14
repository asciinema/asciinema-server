desc "Start Sidekiq Web panel on port 5678"
task :sidekiq_web do
  exec "rackup -p 5678 sidekiq.ru"
end
