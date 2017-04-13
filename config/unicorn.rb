ASCIINEMA_HOME = ENV["ASCIINEMA_HOME"] || Dir.pwd
UNICORN_WORKERS = (ENV["UNICORN_WORKERS"] || "4").to_i

# Use at least one worker per core if you're on a dedicated server,
# more will usually help for _short_ waits on databases/caches.
worker_processes UNICORN_WORKERS

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
working_directory ASCIINEMA_HOME

listen 3000, :tcp_nopush => true

# nuke workers after 60 seconds
timeout 60

# feel free to point this anywhere accessible on the filesystem
pid "#{ASCIINEMA_HOME}/tmp/unicorn.pid"

preload_app true

# Enable this flag to have unicorn test client connections by writing the
# beginning of the HTTP headers before calling the application.  This
# prevents calling the application for connections that have disconnected
# while queued.  This is only guaranteed to detect clients on the same
# host unicorn runs on, and unlikely to detect disconnects even on a
# fast LAN.
check_client_connection false

before_exec do |server|
  ENV["BUNDLE_GEMFILE"] = "#{ASCIINEMA_HOME}/Gemfile"
end

before_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
    Rails.logger.info('Disconnected from ActiveRecord')
  end

  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
    Rails.logger.info('Connected to ActiveRecord')
  end
end
