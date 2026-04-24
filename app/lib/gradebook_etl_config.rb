module GradebookEtlConfig
  class Config
    attr_accessor :sqs_endpoint,
                  :sqs_region,
                  :etl_queue_name,
                  :aws_profile,
                  :access_key_id,
                  :secret_access_key

    # @return [Hash] Sns credentials. This hash can be passed directly to aws-sdk connect method.
    def sqs_config
      { region: sqs_region,
        endpoint: sqs_endpoint }
    end

    # @return [Aws::SharedCredentials or Aws::Credentials or Aws::InstanceProfileCredentials]
    #   all can be used to connect to AWS services.
    def aws_credentials
      require 'aws-sdk'

      @aws_credentials ||=
        if aws_profile
          Aws::SharedCredentials.new(profile_name: aws_profile)
        elsif access_key_id && secret_access_key
          Aws::Credentials.new(access_key_id, secret_access_key)
        else
          Aws::InstanceProfileCredentials.new
        end
    end


    # SQS queue names should be specific to the host
    # that writes to and reads from them. For live/production
    # servers use the configured queue name: gradebook-etl-qa
    # For other environments include the environment name.
    # This will ensure there is no conflict with staging servers
    # whose queue name will include the host designation.
    # e.g. qa20-gradebook-etl-qa.
    def qualified_etl_queue_name
      if Rails.env.live? || Rails.env.production?
        etl_queue_name
      else
        "#{M3::Application.config.current_deployed_env_name}-#{etl_queue_name}"
      end
    end
  end

  # @!method instance
  # @return [Configuration] an instance of configuration.
  #   Defines quick access to ETL configuration attributes
  def configuration
    @configuration ||= Config.new
  end
  module_function :configuration
  #
  # # @yield [configuration] To be used in initializers and environment configurations.
  def configure
    yield(configuration)
  end
  module_function :configure
end
