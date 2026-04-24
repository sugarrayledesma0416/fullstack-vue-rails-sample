module Etl
  module SqsClientWriter
    include EtlLogger

    ERRORS_THAT_HALT_PROCESSING = [
      Aws::SQS::Errors::NonExistentQueue,
      Aws::SQS::Errors::QueueDoesNotExist,
      Aws::SQS::Errors::QueueDoesNotExist
    ].freeze

    # create queue if it does not exists
    # then connect to it
    # get queue info for use later
    def initialize(params)
      @message_attr = params[:model]
      @message_action = params[:action]
      @sqs_client = connect_to_sqs(GradebookEtlConfig.configuration.sqs_config)
      @queue_info = @sqs_client.create_queue(queue_name: GradebookEtlConfig.configuration.qualified_etl_queue_name)
    end

    def send_message(record)
      @current_record = record
      @sqs_client.send_message(
        queue_url: @queue_info.queue_url,
        message_body: record,
        message_attributes: {
          'M3_Model' => {
            string_value: @message_attr,
            data_type: 'String'
          },
          'action' => {
            string_value: @message_action,
            data_type: 'String'
          }
        }
      )
      log_etl_info('enqueue', record, "#{@message_attr}:#{@message_action}")
      # some failures are cause to halt processing,
      # for the rest just log this particular failure and continue
    rescue *ERRORS_THAT_HALT_PROCESSING => e
      log_etl_error('enqueue-fatal-error', e, @message_attr)
      raise e
    rescue Aws::Errors::ServiceError => e
      log_etl_error('enqueue-error', e, @message_attr)
    end

    def connect_to_sqs(region:, endpoint:)
      @sqs_client ||= Aws::SQS::Client.new(region: region,
                                           endpoint: endpoint,
                                           credentials: GradebookEtlConfig.configuration.aws_credentials)
    end
  end
end
