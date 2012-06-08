source 'http://rubygems.org'

gem 'rails'
gem 'jquery-rails'
gem 'tzinfo'
gem 'carrierwave'
gem 'confstruct'
gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-github'
gem 'kaminari'
gem 'airbrake'
gem 'twitter-bootstrap-rails', :git => "git://github.com/seyhunak/twitter-bootstrap-rails.git", :branch => "static"
gem 'fog'
gem 'simple_form'
gem 'girl_friday'
gem 'puma'
gem 'open4'

platforms :mri do
  gem 'mysql2'
  gem 'redcarpet'
  gem 'draper'
end

platforms :rbx do
  gem 'mysql2'
  gem 'redcarpet'
  gem 'draper'
end

platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbcmysql-adapter'
  gem 'kramdown'
  gem 'draper'
  gem 'trinidad'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier', '>= 1.0.3'
  gem 'handlebars_assets'
end

group :development do
  gem 'capistrano'
  gem 'rvm-capistrano'
end

group :test, :development do
  gem "rspec-rails"
  gem 'factory_girl_rails'
  gem 'awesome_print', :require => 'ap'
  gem 'jasmine'
  gem 'jasminerice'
  gem 'guard'
  gem 'guard-jasmine'
  gem 'libnotify'
  gem 'tailor'
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
