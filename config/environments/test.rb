Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  # Below is Dangerfield configuration.
  # See https://github.com/vhl/dangerfield for references.
  Dangerfield.configure do |dangerfield|
    dangerfield.sns_endpoint = 'http://localhost:6061'
    dangerfield.protocol = 'http'
    dangerfield.aws_region = 'us-west-2'
    # If profile set it will be preferred over aws_key_id and aws_access_key
    #dangerfield.aws_profile = 'cmb_local'
    dangerfield.aws_key_id = 'FAKE_AWS_KEY_ID'
    dangerfield.aws_access_key = 'FAKE_AWS_ACCESS_KEY'
    dangerfield.hostname = 'dev.m3.vhlcentral.com'
    dangerfield.raise_errors = true
  end

  ActiveModel::Serializer.root = false

  # Partner chat Cloufront Distribution URL
  config.partner_chat_cdn = 'https://partner-chat.example.com'

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = ENV['SHOW_EXCEPTIONS'].present?
  # It's sometimes useful to have exceptions raised in test env,
  # particularly when running feature specs. Set SHOW_EXCEPTIONS=1
  # (or true, or any non empty value) on the command line when running
  # specs to change the default behaviour.

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  Radner.bucket_name = 'files.dev.vhlcentral.com'
  config.instructor_media_bucket_name = 'media.dev.vhlcentral.com'
  config.s3_activity_bucket_name = 'vhlcentral.activities'

  config.allow_concurrency = false

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  UA_URL = 'https://test.dom:54321'.freeze unless defined?(UA_URL)

  config.after_initialize do
    ClamAntiVirusScan.enabled = false
    ClamAntiVirusScan.detect_fakes = true
    Timecop.safe_mode = true
  end

  # Access to rack session
  config.middleware.use RackSessionAccess::Middleware
  config.submission_datastore = 'xml'

  config.chat_feature_ui = true

  # disable fingerprinting of assets in tests.
  config.assets.digest = false
  # raise exception for missing assets
  config.assets.check_precompiled_asset = true

  # Do not compress css assets
  config.assets.css_compressor = NoCompression.new

  config.sass.cache = false
  config.xapi_encryption_key = '12345678901234567890123456789012'
  config.openai_api_key = 'fake_key'
  config.azure_speech_service_api_key = 'fake_key'

  # this value controls updating of the gradebook during tests
  # it is toggled in rails_helper.rb when new_gb_sync is active
  config.update_test_gradebook = false
  config.hosts << 'www.example.com'
  config.hosts << 'capybara.dev.vhlcentral.com'

  config.hosts << 'capybara.dev.vhlcentral.com'
  config.hosts << 'www.example.com'

  # URI of the Roster Assistant server.
  RA_URL = 'https://roster-assistant.example.com'.freeze unless defined?(RA_URL)

  # Pubnub integration for chat
  config.init_pubnub = false
end
