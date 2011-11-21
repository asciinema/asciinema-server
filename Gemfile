source 'http://rubygems.org'

RAILS_VERSION = '~> 3.1.3'
DM_VERSION    = '~> 1.2.0'
RSPEC_VERSION = '~> 2.7.0'

gem 'activesupport',       RAILS_VERSION, :require => 'active_support'
gem 'actionpack',          RAILS_VERSION, :require => 'action_pack'
gem 'actionmailer',        RAILS_VERSION, :require => 'action_mailer'
gem 'railties',            RAILS_VERSION, :require => 'rails'

gem 'dm-rails',            DM_VERSION
gem 'dm-postgres-adapter', DM_VERSION

gem 'dm-migrations',       DM_VERSION
gem 'dm-types',            DM_VERSION
gem 'dm-validations',      DM_VERSION
gem 'dm-constraints',      DM_VERSION
gem 'dm-aggregates',       DM_VERSION
gem 'dm-timestamps',       DM_VERSION

gem 'jquery-rails'
gem 'tzinfo'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.5'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
end

group :test, :development do
  gem "rspec-rails", RSPEC_VERSION
end

group :test do
  gem "capybara"
end
