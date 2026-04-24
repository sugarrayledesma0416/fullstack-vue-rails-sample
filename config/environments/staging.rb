# Defines the majority of config options, common to qa/staging/live envs.
require_relative '../common_server_environment'

Rails.application.configure do
  # Bellow is Dangerfield configuration.
  # See https://github.com/vhl/dangerfield for references.
  Dangerfield.configure do |dangerfield|
    dangerfield.hostname = ENV['QA_HOSTNAME']
    dangerfield.cloudwatch_success_aim = 'arn:aws:iam::774082247212:role/qa-core-staging-DangerfieldCloudwatchRole-HKB8CSDFIDGW'
    dangerfield.cloudwatch_failure_aim = 'arn:aws:iam::774082247212:role/qa-core-staging-DangerfieldCloudwatchRole-HKB8CSDFIDGW'
    dangerfield.cloudwatch_recovery_log_groupname = 'rostering_recovery_logs_staging'
  end

  # Partner chat Cloudfront Distribution URL
  config.partner_chat_cdn = 'https://partner-chat-recordings.ms.vhlcentral.com'
  config.vonage_media_bucket_name = 'partner-chat-recordings.ms.vhlcentral.com'

  # analytics tracking account
  LOCAL_ANALYTICS_ACCOUNT = 'UA-17436181-1'.freeze unless defined? LOCAL_ANALYTICS_ACCOUNT

  # Gradebook dev features should be hidden without dev cookie, as in live environment.
  config.enable_gradebook_dev_features = false

  config.chat_feature_ui = true

  # Mail setup
  config.action_mailer.perform_deliveries = false

  config.submission_datastore = 'xml'
end
