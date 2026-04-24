# This file extracts configuration that's otherwise duplicated among
# config/environments/production.rb, qa.rb, staging.rb, and live.rb.
# Each of those environments requires this file, then adds any
# additional configuration if necessary.
# Up until the block starting with the comment: "VHL Settings", this file
# is basically what rails would generate as the default contents of
# config/environments/production.rb.

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  # config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass
  config.assets.compress = true

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "m3_#{Rails.env}"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  # config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  ## VHL Settings

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # VHL Override for compression settings -- this will apply to JS only
  # because CSS is automatically minified by Sass without specifying a
  # compressor (as long as config.assets.compress is true).
  config.assets.js_compressor = NoCompression.new
  config.assets.css_compressor = NoCompression.new

  config.after_initialize do
    # Antivirus scans can be slow (2-3 seconds), so they should only be used
    # in environments that are externally accessible (including qa servers).

    # If false, no real scans will be performed.  Fake scans may still be
    # performed, if enabled.
    ClamAntiVirusScan.enabled = true

    # If true, a file that has a filename of virus, with any extension
    # (e.g. virus.txt, virus.fake) will be detected as a virus, and
    # report a detected virus name of "Virus.Based.0N.Filename". This can
    # be useful for demonstrating virus-scanning behaviour (e.g. in
    # iteration reviews).  Real scans may also be performed, if enabled,
    # allowing this setting to be used safely on servers that are
    # externally accessible.
    ClamAntiVirusScan.detect_fakes = true
  end

  CURRENT_HOST = `hostname`.chomp.split('.').first.freeze

  Dangerfield.configure do |dangerfield|
    dangerfield.sns_endpoint = 'https://sns.us-east-1.amazonaws.com'
    dangerfield.protocol = 'https'
    dangerfield.aws_region = 'us-east-1'
    dangerfield.raise_errors = true
    dangerfield.verify_requests = true
    dangerfield.logger = Rails::Rack::Logger
    dangerfield.dog_api_key = ENV['DATADOG_API_KEY']
    dangerfield.dog_application_key = ENV['DATADOG_APPLICAITON_KEY']
    dangerfield.sns_topics_config = Rails.root.join('config', 'aws_sns_subscribers.yml')
  end

  require_relative '../app/models/vitalsource'
  Vitalsource.configure do |config|
    config.api_url = 'https://api.vitalsource.com'
    config.api_key = ENV['VITALSOURCE_API_KEY']
    config.bookshelf_url = 'https://online.vitalsource.com/books'
  end

  config.xapi_encryption_key = ENV['XAPI_ENCRYPTION_KEY']
  config.openai_api_key = ENV.fetch('OPENAI_API_KEY', '')
  config.azure_speech_service_api_key = ENV.fetch('AZURE_SPEECH_SERVICE_API_KEY', '')

  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  # custom_options can be a lambda or hash
  # if it's a lambda then it must return a hash
  config.lograge.custom_options = lambda do |event|
    correlation = Datadog::Tracing.correlation
    {}.tap do |result|
      result['pid'] = Process.pid
      result['ip'] = event.payload['ip']
      # To avoid entries like "user_guid=", we only set keys that have non-blank values.
      result['user_id'] = event.payload['user_id'] if event.payload['user_id']
      result['user_guid'] = event.payload['user_guid'] if event.payload['user_guid']
      result['params'] = event.payload['params'] if event.payload['params'].present?
      result['_csrf_token'] = event.payload['_csrf_token'] if event.payload['_csrf_token'].present?
      # Datadog integration:
      #     https://docs.datadoghq.com/tracing/connect_logs_and_traces/ruby/
      result['dd'] = {
        # To preserve precision during JSON serialization, use strings for large numbers
        'env' => Rails.env.to_s,
        'service' => correlation.service.to_s,
        'span_id' => correlation.span_id.to_s,
        'trace_id' => correlation.trace_id.to_s,
        'version' => correlation.version.to_s
      }
      result['ddsource'] = ['ruby']
    end
  end

  # Use instance profiles for authentication
  Radner.use_aws_credentials = false

  # Pubnub integration for chat
  config.init_pubnub = true
end
