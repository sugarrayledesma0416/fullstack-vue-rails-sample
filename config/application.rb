require_relative 'boot'
require 'rails/all'
require_relative './no_compression'
require_relative '../app/lib/vhl_monitor'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module M3
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Use zeitwerk mode for the autoloader
    config.autoloader = :zeitwerk

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # NOTE: These time_zone related settings seem to want to live in this file even
    # though this was not necessary on UA.
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    Rails.configuration.time_zone = 'Eastern Time (US & Canada)'

    # Time columns will become time zone aware in Rails 5.1. This
    # still causes `String`s to be parsed as if they were in `Time.zone`,
    # and `Time`s to be converted to `Time.zone`.
    #
    # To keep the old behavior, you must add the following to your initializer:
    #   config.active_record.time_zone_aware_types = [:datetime]
    #
    # To use the new behavior, add the following:
    #   config.active_record.time_zone_aware_types = [:datetime, :time]
    # We are only using one time column, the "due time" field of sections
    # table, and we already handle the logic for making it time zone aware.
    # Trying to change this to use Rails' built-in handling will probably be
    # a nightmare, so it seems safest to continue using our own implementation.
    Rails.configuration.active_record.time_zone_aware_types = [:datetime]

    config.etl_log_level = :info
    config.log_faraday_requests = false

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W{
      #{config.root}/app/middleware
      #{config.root}/app/lib/validators
    }

    config.exceptions_app = self.routes
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.

    # initialize config variables for maestro_monitoring
    config.maestro_monitoring = nil

    config.enable_gradebook_dev_features = false
    config.enable_analytics = true

    # X-Frame-Options configuration: Allow embed VHL pages into external LMSes.
    # TODO: White list the different URLs of all the different 3rd party LMSes.
    config.action_dispatch.default_headers = {
      'X-Frame-Options' => 'ALLOWALL'
    }

    # Setting to false for VHL to try and prevent
    # https://rollbar.com/vhl/ua/items/6015
    # It seems like it has to be set in application.rb instead of in
    # config/initializers or the setting doesn't get picked up.
    config.action_controller.forgery_protection_origin_check = false


    # Disable writing URI metadata to the Link header as this was
    # causing "response header too big" errors in nginx when viewing
    # some activities.
    #
    # https://guides.rubyonrails.org/6_1_release_notes.html#action-view-notable-changes
    config.action_view.preload_links_header = false
  end

  Encoding.default_internal = 'utf-8'
  Encoding.default_external = 'utf-8'

  # Hide pg gem deprecation warnings... these will go away when we upgrade
  # the pg gem to 1.0.0 with Rails 5.2
  ENV['PG_SKIP_DEPRECATION_WARNING'] = 'true'
end
