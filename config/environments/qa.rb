# Defines the majority of config options, common to qa/staging/live envs.
require_relative '../common_server_environment'

Rails.application.configure do
  # Bellow is Dangerfield configuration.
  # See https://github.com/vhl/dangerfield for references.
  Dangerfield.configure do |dangerfield|
    dangerfield.hostname = ENV['QA_HOSTNAME']
    dangerfield.cloudwatch_success_aim = 'arn:aws:iam::375760863033:role/qa-core-DangerfieldCloudwatchRole-M6HLVMR0HRW0'
    dangerfield.cloudwatch_failure_aim = 'arn:aws:iam::375760863033:role/qa-core-DangerfieldCloudwatchRole-M6HLVMR0HRW0'
    dangerfield.cloudwatch_recovery_log_groupname = 'rostering_recovery_logs_staging'
  end

  # Partner chat Cloudfront Distribution URL
  config.partner_chat_cdn = 'https://partner-chat-recordings.qa.vhlcentral.com'
  config.vonage_media_bucket_name = 'partner-chat-recordings.qa.vhlcentral.com'

  # analytics tracking account
  LOCAL_ANALYTICS_ACCOUNT = 'UA-17436181-1'.freeze unless defined? LOCAL_ANALYTICS_ACCOUNT

  # Gradebook dev features should be hidden without dev cookie, as in live environment.
  config.enable_gradebook_dev_features = false

  config.chat_feature_ui = true

  # Mail setup
  config.action_mailer.perform_deliveries = false

  # Turn this on to get see errors traces in browser. Turn it off to see
  # error messages that look more like what customers see.
  config.consider_all_requests_local = true

  config.static_cache_control = 'public, max-age=3600'

  MEDIA_BUCKET_URL = 'https://media.qa.vhlcentral.com'.freeze
  # used to access svg content for hotspots activity
  config.s3_media_bucket_name = 'media.maestro.vhlcentral.com'

  # Standards opensearch cluster setup
  config.standards_opensearch_url = 'https://vpc-standards-vfaja65pdqlvw2seu5x3zh3pgq.us-east-1.es.amazonaws.com'

  config.opensearch_username = 'standards_master_user'.freeze
  config.opensearch_password = ENV.fetch('OPENSEARCH_PASSWORD', '')
  config.opensearch_num_shards = 2 # equal to number of data nodes
  config.opensearch_num_replicas = 1

  # enable faraday stats
  config.log_faraday_requests = true
end
