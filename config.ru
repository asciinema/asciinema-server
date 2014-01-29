# This file is used by Rack-based servers to start the application.

if ENV['RAILS_ENV'] == 'production'
  require 'unicorn/worker_killer'
  use Unicorn::WorkerKiller::Oom, (160*(1024**2)), (180*(1024**2))
end

require ::File.expand_path('../config/environment',  __FILE__)

use Rack::Deflater

run Asciinema::Application
