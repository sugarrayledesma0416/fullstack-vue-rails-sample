module StandardsMapping
  module Etl
    class StandardAlignmentTransform
      include UploadTypes

      def initialize(config_params)
        @config_params = config_params
        @last_upload_date = @config_params[:last_upload_date]
        @converter = StandardAlignmentIndexConverter.new
      end

      def process(record)
        @std = record.standard
        @std_asset = record.standard_asset
        if @config_params[:upload_type] == INITIAL_UPLOAD_TYPE ||
           record.created_at > @last_upload_date ||
           @std_asset.created_at > @last_upload_date ||
           @std.created_at > @last_upload_date
          transform_to_new_document(record)
        elsif update_doc?(record)
          transform_to_updated_document(record)
        end
      end

      private def transform_to_new_document(record)
        transformation = []
        transformation << { index: {
          _index: OpenSearchClient.opensearch_std_alignments_alias,
          _id: record.id
        } }
        transformation << transform_mapped_item(record)
      end

      private def transform_to_updated_document(record)
        transformation = []
        transformation << { update: {
          _index: OpenSearchClient.opensearch_std_alignments_alias,
          _id: record.id
        } }
        transformation << { doc: transform_mapped_item(record) }
      end

      private def transform_mapped_item(record)
        @converter.convert(record, @std, @std_asset)
      end

      private def update_doc?(record)
        record.updated_at > @last_upload_date ||
        @std.updated_at > @last_upload_date ||
        @std_asset.updated_at > @last_upload_date
      end
    end
  end
end
