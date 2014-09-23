ENV["RAILS_ENV"] ||= 'test'

require 'spec_helper'

if ENV["CI"] && (!defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby")
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start 'rails' do
    add_group "Decorators", "app/decorators"
    add_group "Presenters", "app/presenters"
  end
end

ENV['CARRIERWAVE_STORAGE_DIR_PREFIX'] ||= 'uploads/test/'

require File.expand_path("../../config/environment", __FILE__)
ActiveRecord::Migration.maintain_test_schema!

require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'sidekiq/testing'
require 'pundit/rspec'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/shared/**/*.rb")].each  { |f| require f }

Capybara.javascript_driver = :poltergeist

OmniAuth.config.test_mode = true

CarrierWave.configure do |config|
  config.storage = :file
  config.enable_processing = false
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!

  config.include FactoryGirl::Syntax::Methods
  config.include Asciinema::FixtureHelpers
  config.include Asciinema::FeatureHelpers

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
