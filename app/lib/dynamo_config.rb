require 'aws-sdk-dynamodb'

module DynamoConfig
  mattr_accessor :local_pid

  class << self
    def client
      @client ||= Aws::DynamoDB::Client.new(client_opts)
    end

    def client_opts
      { region: region }.merge(use_local? ? local_client_opts : {})
    end

    def region
      config[:region] || 'us-east-1'
    end

    def config
      configurations.fetch(Rails.env, {})
    end

    def configurations
      @configurations ||= load_configurations.with_indifferent_access
    end

    def load_configurations
      yaml_file = Rails.root.join('config', 'dynamodb.yml')
      File.exist?(yaml_file) && YAML.load_file(yaml_file, aliases: true) || {}
    end

    def use_local?
      config[:local_port].to_i.positive?
    end

    def spawn_local?
      use_local? && config[:spawn_local]
    end

    def port
      config[:local_port].to_i + ENV['TEST_ENV_NUMBER'].to_i
    end

    def local_client_opts
      {
        endpoint: "http://localhost:#{port}",
        stub_responses: false
      }
    end
  end
end
