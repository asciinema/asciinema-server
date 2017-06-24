require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

require File.expand_path('../cfg', __FILE__)

module Asciinema
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/app/decorators/helpers)

    # Disable generation of helpers, javascripts, css, and view specs
    config.generators do |generate|
      generate.helper false
      generate.assets false
      generate.view_specs false
    end

    config.i18n.enforce_available_locales = true

    config.middleware.use ::Rack::Robustness do |g|
      g.no_catch_all
      g.on(ArgumentError) { |ex| 400 }
      g.content_type 'text/plain'
      g.body{ |ex| ex.message }
      g.ensure(true) { |ex| env['rack.errors'].write(ex.message) }
    end

    # It seems some browsers (Firefox) use encoded "~" character which for
    # unknown reason isn't properly decoded by rack and/or Rails router.
    config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
      rewrite /%7E(.+)/i, '/~$1'
    end

    config.middleware.use 'MetadataParser'
    config.middleware.use 'ApiTokenRegistrator'

    config.middleware.use 'Warden::Manager' do |manager|
      manager.failure_app = ApplicationController
      manager.scope_defaults(
        :user,
        strategies: [:auth_cookie],
        store: true,
        action: "unauthenticated_user"
      )
    end

    config.action_mailer.default_url_options = {
      protocol: CFG.url_scheme,
      host: CFG.url_host,
      port: CFG.url_port
    }

    if CFG.smtp_settings
      config.action_mailer.smtp_settings = CFG.smtp_settings
    end
  end
end
