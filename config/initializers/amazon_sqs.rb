require 'gradebook_etl_config'

aws_sqs_config = YAML.load(File.open(Rails.root.join('config/amazon_sqs.yml')))[Rails.env]
GradebookEtlConfig.configure do |config|
  config.sqs_region = aws_sqs_config['sqs_region']
  config.etl_queue_name = aws_sqs_config['etl_queue_name']
  config.sqs_endpoint = aws_sqs_config['sqs_endpoint']
  config.aws_profile = aws_sqs_config['aws_profile']
  config.access_key_id = aws_sqs_config['access_key_id']
  config.secret_access_key = aws_sqs_config['secret_access_key']
end
