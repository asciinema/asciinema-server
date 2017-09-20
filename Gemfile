source 'https://rubygems.org'

gem 'rails',                '4.1.13'

gem 'sass-rails'
gem 'uglifier'
gem 'jquery-rails',         '~> 3.0.4'

gem 'pg',                   '~> 0.14'
gem 'carrierwave',          '~> 0.8.0'
gem 'kaminari',             '~> 0.14.1'
gem 'bugsnag',              '~> 2.2.1'
gem 'draper',               '~> 1.3.1'
gem 'fog',                  '~> 1.19.0'
gem 'simple_form',          '~> 3.0.2'
gem 'simple_form_bootstrap3', '~> 0.2.6'
gem 'sidekiq',              '~> 3.2.2'
gem 'thin',                 '~> 1.5.0'
gem 'open4',                '~> 1.3.0'
gem 'redcarpet',            '~> 3.4.0'
gem 'slim',                 '~> 2.0.0'
gem 'dotenv-rails',         '~> 0.8'
gem 'sinatra',              '~> 1.4.3', :require => false
gem 'active_model_serializers', '~> 0.8.1'
gem 'yajl-ruby',            '~> 1.1.0', :require => 'yajl'
gem 'virtus',               '~> 1.0.1'
gem 'rails_warden',         '~> 0.5.8'
gem 'pundit',               '~> 0.3.0'
gem 'rack-robustness',      '~> 1.1.0'
gem 'rack-rewrite',         '~> 1.5.0'
gem 'oj',                   '~> 2.17.4'
gem 'oj_mimic_json',        '~> 1.0'
gem 'foreigner',            '~> 1.7'
gem 'rails-default-database'

group :development do
  gem 'quiet_assets',   '~> 1.0.1'
  gem 'foreman',        '~> 0.63.0'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'immigrant'
end

group :test, :development do
  gem 'pry-rails',     '~> 0.3.2'
  gem 'rspec-rails',   '~> 3.0.2'
  gem 'cane',          '~> 2.5.2'
  gem 'timecop',       '~> 0.7.1'
end

group :test do
  gem "rake",               '~> 10.0.4'
  gem 'factory_girl_rails', '~> 4.2.0'
  gem 'capybara',           '~> 2.4.1'
  gem 'poltergeist',        '~> 1.6.0'
  gem 'database_cleaner',   '~> 1.0.1'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify', require: RUBY_PLATFORM.include?('linux') && 'rb-inotify'
  gem 'shoulda-matchers'
  gem 'coveralls',          require: false
  gem 'rspec-activemodel-mocks'
  gem 'chunky_png'
end

group :production do
  gem 'unicorn',               '~> 4.7'
  gem 'dalli',                 '~> 2.6.2'
  gem 'unicorn-worker-killer', '~> 0.4.2'
end
