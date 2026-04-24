module StandardsMapping
  module Etl
    class StandardAssetTransform
      include UploadTypes

      def initialize(config_params)
        # not sure params needed but just in case
        # think about logging - might need logger handle
        # # pass in load type - if it is "initial" we transform to
        # create document json;
        # if it is "update", we need to know when the last upload occurred
        # so we know which records are new vs updated
        @config_params = config_params
        @last_upload_date = @config_params[:last_upload_date]
        @converter = StandardAssetConverter.new
      end

      # We determined that we would only upload a StandardAsset if
      # it has alignments. We will use the date_alignments_modified_utc
      # value to check this. If it is nil then there are none.
      # In those cases we return nil which tells the Kiba ETL
      # to skip this record.
      # ToDo Also return nil for any record that does not
      # require processing as it is either not new or has not been
      # updated since the last_upload_date.
      def process(record)
        return if record.date_alignments_modified_utc.blank?

        # look at created_at date against last_upload_date to determine
        # whether the standard_asset is new;
        # to determine whether or not a new version needs to be uploaded,
        # check updated_at and date_alignments_modified_utc
        if @config_params[:upload_type] == INITIAL_UPLOAD_TYPE ||
           record.created_at > @last_upload_date
          transform_to_new_document(record)
        elsif record.date_alignments_modified_utc > @last_upload_date ||
              record.updated_at > @last_upload_date
          transform_to_updated_document(record)
        end
      end

      private def transform_to_new_document(record)
        # creates a new document for the OpenSearch index.
        # we use the record id (StandardAsset instance id)
        # as the OpenSearch index.
        transformation = []
        transformation << { index: { _index: OpenSearchClient.opensearch_std_assets_index, _id: record.id } }
        transformation << transform_mapped_item(record)
      end

      # the JSON cannot include any lines breaks except one at  the end
      private def transform_to_updated_document(record)
        # updates an existing document in the OpenSearch index.
        # the only difference is the first index block before
        # the actual document.
        transformation = []
        transformation << { update: { _index: OpenSearchClient.opensearch_std_assets_index, _id: record.id } }
        # then do the actual item
        transformation << { doc: transform_mapped_item(record) }
      end

      private def transform_mapped_item(record)
        # this is where we create the document for the mapped
        # item that includes all its properties and the
        # list of alignments with the properties of each.
        @converter.convert(record)
      end
    end
  end
end
