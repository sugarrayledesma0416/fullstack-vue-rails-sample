SubmissionClient.configure do |config|
  config.factory_namespace =  SubmissionClient
  config.service_namespace = SubmissionClient::Service
  config.api_server_ip =  (defined?(SUBMISSION_API_SERVER_IP) && SUBMISSION_API_SERVER_IP) || 'localhost'
  config.api_server_port = (defined?(SUBMISSION_API_SERVER_PORT) && SUBMISSION_API_SERVER_PORT) || 80
  config.api_username  =  (defined?(SUBMISSION_API_USERNAME) && SUBMISSION_API_USERNAME) || 'maestro'
  config.api_password = ENV['SUBMISSION_API_PASSWORD'] || (defined?(SUBMISSION_API_PASSWORD) && SUBMISSION_API_PASSWORD) || 'password'
  config.api_server_protocol = (defined?(SUBMISSION_API_SERVER_PROTOCOL) && SUBMISSION_API_SERVER_PROTOCOL) || 'http'
  config.use_instrumentation = true
end

#active submission data store
Rails.application.configure do
  config.submission_datastore = (defined?(SUBMISSION_STORE_MODE) && SUBMISSION_STORE_MODE) || 'xml'
  config.percent_of_read_requests_to_api = (defined?(SUBMISSION_STORE_READ_PERCENT) && SUBMISSION_STORE_READ_PERCENT) || 0
  config.percent_of_write_requests_to_api = (defined?(SUBMISSION_STORE_WRITE_PERCENT) && SUBMISSION_STORE_WRITE_PERCENT) || 0
end
