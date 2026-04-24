raw_yaml = Rails.root.join('config', 'api_cache.yml').read
redis_config = YAML.safe_load(raw_yaml, aliases: true)[Rails.env]

Maestro.configure do |config|
  config.factory_namespace = Maestro
  config.service_namespace = Maestro::Service
  config.api_server_ip = (defined?(MAESTRO_API_SERVER_IP) && MAESTRO_API_SERVER_IP) || 'localhost'
  config.api_server_port = (defined?(MAESTRO_API_PORT) && MAESTRO_API_PORT) || 80
  config.api_server_protocol = (defined?(MAESTRO_API_PROTOCOL) && MAESTRO_API_PROTOCOL) || 'http'
  config.api_username = (defined?(MAESTRO_API_USERNAME) && MAESTRO_API_USERNAME) || 'maestro'
  config.api_password = (defined?(MAESTRO_API_PASSWORD) && MAESTRO_API_PASSWORD) || 'test'
  config.use_instrumentation = true

  config.api_redis_enabled = redis_config['api_redis_enabled']
  config.api_redis_host = redis_config['api_redis_host']
  config.api_redis_port = redis_config['api_redis_port']
  config.api_redis_timeout = redis_config['api_redis_timeout']
  config.api_redis_password = redis_config['api_redis_password']
end
