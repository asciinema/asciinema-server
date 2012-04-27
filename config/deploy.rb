$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"
require 'bundler/capistrano'
require 'capistrano_colors'
require 'sidekiq/capistrano'

ssh_options[:forward_agent] = true

set :application, "ascii.io"

set :scm, :git
set :repository, "git://github.com/sickill/ascii.io.git"
set :branch, ENV["REV"] || ENV["REF"] || ENV["BRANCH"] || ENV["TAG"] || "master"

set :domain, "ascii.io"
role :web, domain
role :app, domain
role :db,  domain, :primary => true

set :rails_env, "production"

set :user, "asciiio"
set :use_sudo, false
set :deploy_to, "~/app"
set :keep_releases, 3

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end

  desc "Symlink shared files/directories"
  task :symlink_shared, :roles => :app do
    cmd = "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    cmd << " && ln -nfs #{shared_path}/config/local.yml #{release_path}/config/local.yml"
    run cmd
  end

  desc "Precompile assets"
  task :assets_precompile do
    run "cd #{release_path}; RAILS_ENV=#{rails_env} bundle exec rake assets:precompile"
  end
end

after 'deploy:update_code', 'deploy:symlink_shared'
after 'deploy:update_code', 'deploy:assets_precompile'
