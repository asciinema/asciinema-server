if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_group "Decorators", "app/decorators"
  end
end

ENV["RAILS_ENV"] ||= 'test'
ENV['CARRIERWAVE_STORAGE_DIR_PREFIX'] ||= 'uploads/test/'

require File.expand_path("../../config/environment", __FILE__)

require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'sidekiq/testing'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/shared/**/*.rb")].each  { |f| require f }

Capybara.javascript_driver = :poltergeist

OmniAuth.config.test_mode = true

CarrierWave.configure do |config|
  config.storage = :file
  config.enable_processing = false
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = false
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"

  config.include FactoryGirl::Syntax::Methods
  config.include Asciinema::FixtureHelpers
  config.include Asciinema::FeatureHelpers
  config.include Asciinema::ControllerMacros, :type => :controller

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
