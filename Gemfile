source 'http://rubygems.org'

gem 'rails'
gem 'jquery-rails'
gem 'tzinfo'
gem 'carrierwave'
gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-github'
gem 'kaminari'
gem 'airbrake'
gem 'draper'
gem 'fog'
gem 'simple_form'
gem 'girl_friday'
gem 'unicorn'
gem 'open4'
gem 'redcarpet'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier', '>= 1.0.3'
  gem 'handlebars_assets'
end

group :test, :development do
  gem 'mysql2'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'awesome_print', :require => 'ap'
  gem 'jasmine'
  gem 'jasminerice'
  gem 'guard'
  gem 'guard-jasmine'
  gem 'libnotify'
  gem 'cane'
  gem 'tailor'
  gem 'quiet_assets'
  # gem 'jasmine-headless-webkit'
  # gem 'guard-jasmine-headless-webkit'
end

group :test do
  gem "rake"
  gem "capybara"
  gem 'simplecov', :require => false
end

group :bugfix do
  gem 'handlebars_assets'
end

group :production do
  gem 'pg'
  gem 'dalli'
end
