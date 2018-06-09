ENV["RAILS_ENV"] ||= 'test'

require 'spec_helper'

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
