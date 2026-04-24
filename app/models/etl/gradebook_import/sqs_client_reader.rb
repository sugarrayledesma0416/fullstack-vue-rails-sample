module Etl
  module GradebookImport
    module SqsClientReader
      include EtlLogger

      AWS_MAX_MESSAGES = 10
      # get queue info for use later
      # TBD error out if queue does not exist
      def initialize(num_messages = 1)
        # avoid AWS error by adjusting size of read batch to
        # ensure it is not more than AWS max of 10
        @num_messages = [num_messages, AWS_MAX_MESSAGES].min
        @sqs_client = connect_to_sqs(GradebookEtlConfig.configuration.sqs_config)
        @queue_info = @sqs_client.get_queue_url(queue_name: GradebookEtlConfig.configuration.qualified_etl_queue_name)
      end

      def receive_messages
        response = @sqs_client.receive_message(
          queue_url: @queue_info.queue_url,
          message_attribute_names: %w(M3_Model action),
          max_number_of_messages: @num_messages,
          visibility_timeout: 5,
          wait_time_seconds: 1
        )
        @messages = response.messages
        # any read failure should halt processing
      rescue Aws::Errors::ServiceError => e
        log_etl_error('dequeue-fatal-error', e)
        raise e
      end

      def connect_to_sqs(region:, endpoint:)
        @sqs_client ||= Aws::SQS::Client.new(region: region,
                                             endpoint: endpoint,
                                             credentials: GradebookEtlConfig.configuration.aws_credentials)
      end

      def delete_message(receipt_handle)
        @sqs_client.delete_message(
          queue_url: @queue_info.queue_url,
          receipt_handle: receipt_handle
        )
      end
    end
  end
end
