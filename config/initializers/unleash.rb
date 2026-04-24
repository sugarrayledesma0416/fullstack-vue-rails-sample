require 'unleash'
require 'yaml'
require 'erb'
require 'logger'

def configure_unleash
  log_file_path = Rails.root.join('log', "unleash-#{Rails.env}.log")
  unleash_logger = Logger.new(log_file_path, 'daily')

  # Process ERB in YAML file to substitute environment variables
  yaml_content = File.read(Rails.root.join('config', 'unleash.yml'))
  erb_processed = ERB.new(yaml_content).result
  unleash_config = YAML.safe_load(erb_processed)[Rails.env]

  Unleash.configure do |config|
    config.url = unleash_config['url']
    config.app_name = unleash_config['app_name']
    config.environment = Rails.env
    config.custom_http_headers = { 'Authorization' => ENV['UNLEASH_API_KEY'] }
    config.logger = unleash_logger
    config.log_level = Logger::DEBUG

    # Enhanced network settings for reliable connectivity
    config.refresh_interval = 30 # Refresh every 30 seconds
    config.timeout = 30          # 30 second connection timeout
    config.retry_limit = 5       # Retry failed requests 5 times

    # Bootstrap used to specify feature flag defaults before it is fetched from the Unleash server
    # Load from feature_flags.yml if available
    bootstrap_features = {}
    feature_config_file = Rails.root.join('config', 'feature_flags.yml')

    if File.exist?(feature_config_file)
      feature_config = YAML.safe_load(File.read(feature_config_file))
      if feature_config && feature_config['feature_flags']
        feature_config['feature_flags'].each do |flag_name, flag_config|
          bootstrap_features[flag_name] = {
            'enabled' => flag_config['default'] || false,
            'strategies' => [
              {
                'name' => 'default',
                'parameters' => {}
              }
            ]
          }
        end
      end
    end

    config.bootstrap_config = Unleash::Bootstrap::Configuration.new(bootstrap_features)
  end

  Unleash::Client.new
end

if ENV['UNLEASH_API_KEY'].present?
  if defined?(PhusionPassenger)
    PhusionPassenger.on_event(:starting_worker_process) do |forked|
      if forked
        UNLEASH = configure_unleash
      end
    end
  else
    UNLEASH = configure_unleash
  end
end
