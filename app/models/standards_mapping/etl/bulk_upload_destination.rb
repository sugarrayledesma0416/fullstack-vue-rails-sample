module StandardsMapping
  module Etl
    class BulkUploadDestination
      attr_reader :batch_size

      # We want to bulk load a batch of JSON documents
      # to OpenSearch via the API.
      # This destination will gather batches and
      # write them as we reach the batch_size.
      # It will write the remaining after it gets the last one.
      def initialize(config_params)
        #not clear yet whether or not the OpenSearchUploader requires any params
        @uploader = OpenSearchUploader.new(config_params)
        @batch_size = config_params[:batch_size]
        @transformed_records = []
      end

      def write(transformed_record)
        @transformed_records = @transformed_records + transformed_record
        flush if @transformed_records.size >= batch_size
      end

      def close
        flush
      end

      def flush
        @uploader.post_batch(@transformed_records)
        @transformed_records = []
      end
    end
  end
end
