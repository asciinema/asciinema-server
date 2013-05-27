source 'http://rubygems.org'

gem 'rails',            '3.2.13'
gem 'jquery-rails',     '~> 2.2.0'
gem 'pg',               '~> 0.14.1'
gem 'carrierwave',      '~> 0.8.0'
gem 'omniauth',         '~> 1.1.4'
gem 'omniauth-twitter', '~> 0.0.16'
gem 'omniauth-github',  '~> 1.1.0'
gem 'kaminari',         '~> 0.14.1'
gem 'airbrake',         '~> 3.1.7', :require => false
gem 'draper',           '~> 1.2.1'
gem 'fog',              '~> 1.9.0'
gem 'simple_form',      '~> 2.0.4'
gem 'girl_friday',      '~> 0.11.2'
gem 'thin',             '~> 1.5.0'
gem 'open4',            '~> 1.3.0'
gem 'redcarpet',        '~> 2.2.2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.6'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier',     '>= 1.0.3'
end

group :development do
  gem 'quiet_assets', '~> 1.0.1'
end

group :test, :development do
  gem 'pry-rails',     '~> 0.2.2'
  gem 'rspec-rails',   '~> 2.12.2'
  gem 'cane',          '~> 2.5.2'
  gem 'jasmine-rails', '~> 0.3.2'
end

group :test do
  gem "rake",                          '~> 10.0.4'
  gem 'factory_girl_rails',            '~> 4.2.0'
  gem 'capybara',                      '~> 2.0.2'
  gem 'poltergeist',                   '~> 1.1.2'
  gem 'database_cleaner',              '~> 0.9.1'
  gem 'guard',                         '~> 1.6.2'
  gem 'guard-rspec',                   '~> 2.4.0'
  gem 'guard-jasmine-headless-webkit', '~> 0.3.2'
  gem 'rb-inotify',                    '~> 0.8.8'
  gem 'simplecov',                     '~> 0.7.1', :require => false
end

group :production do
  gem 'unicorn', '~> 4.5.0'
  gem 'dalli',   '~> 2.6.2'
end
