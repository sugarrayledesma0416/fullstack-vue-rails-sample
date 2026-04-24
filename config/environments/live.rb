# Defines the majority of config options, common to qa/staging/live envs.
require_relative '../common_server_environment'
require_relative '../../app/lib/vhl_monitor/middleware'

Rails.application.configure do
  # Bellow is Dangerfield configuration.
  # See https://github.com/vhl/dangerfield for references.
  Dangerfield.configure do |dangerfield|
    dangerfield.hostname = 'm3a.vhlcentral.com'
    dangerfield.cloudwatch_success_aim = 'arn:aws:iam::097392476160:role/VHL_SNSSuccessFeedback'
    dangerfield.cloudwatch_failure_aim = 'arn:aws:iam::097392476160:role/VHL_SNSFailureFeedback'
    dangerfield.cloudwatch_recovery_log_groupname = 'rostering_recovery_logs_live'
  end

  # Partner chat Cloudfront Distribution URL
  config.partner_chat_cdn = 'https://partner-chat-recordings.maestro.vhlcentral.com'
  config.vonage_media_bucket_name = 'partner-chat-recordings.maestro.vhlcentral.com'

  # analytics tracking account
  LOCAL_ANALYTICS_ACCOUNT = 'UA-1920613-1'.freeze unless defined? LOCAL_ANALYTICS_ACCOUNT

  # gradebook dev features should be hidden in live environment.
  config.enable_gradebook_dev_features = false

  config.chat_feature_ui = false

  # Mail setup
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :mailgun
  config.action_mailer.mailgun_settings = {
    api_key: ENV['MAILGUN_API_KEY'],
    domain: 'e.vistahigherlearning.com'
  }

  # Fetch assets from CloudFront.
  config.action_controller.asset_host = 'assets.maestro.vhlcentral.com'

  config.log_level = :info

  IGNORED_404_PATHS = ['/vtext/', '/media_items/live/flash_reading'].freeze
  IGNORED_404_PATHS_REGEXP = Regexp.new("^#{IGNORED_404_PATHS.join('|^')}")

  # return true here if you want to ignore based on the event
  config.lograge.ignore_custom = lambda do |event|
    event.payload[:status] == 404 && event.payload[:path] =~ IGNORED_404_PATHS_REGEXP
  end

  config.after_initialize do
    ClamAntiVirusScan.detect_fakes = false
  end

  # enable ARC logging
  ENABLE_ARC_LOGGING = true

  # monitors define exceptions (include message pattern to monitor)
  # you can add your own monitors
  # see lib/maestro_monitoring/notifier.rb for possible monitors and format
  config.maestro_monitoring = [:mysql_server_errors]

  # Insert VHLMonitor for collection reports on some exceptions
  config.middleware.insert_after(
    ActionDispatch::DebugExceptions, VHLMonitor::Middleware
  )

  # Reduce etl log verbosity in live env
  config.etl_log_level = :error

  # enable faraday stats
  config.log_faraday_requests = true

  # Standards opensearch cluster setup
  config.standards_opensearch_url = 'https://vpc-standards-v4muxx4pqtjp6b3evxp6jjstka.us-east-1.es.amazonaws.com'

  config.opensearch_username = 'standards_master_user'.freeze
  config.opensearch_password = ENV.fetch('OPENSEARCH_MASTER_USER_PASSWORD', '')
  config.opensearch_num_shards = 4 # equal to number of data nodes
  config.opensearch_num_replicas = 1
end
