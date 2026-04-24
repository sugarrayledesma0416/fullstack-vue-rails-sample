module StandardsMapping
  module Etl
    class StandardTransform
      include UploadTypes
      def initialize(config_params)
        # pass in load type - if it is "initial" we transform to
        # create document json;
        # if it is "update", we need to know when the last upload occurred
        # so we know which records are new vs updated
        @config_params = config_params
        @last_upload_date = config_params[:last_upload_date]
        @upload_type = @config_params[:upload_type]
        @converter = StandardConverter.new
      end

      # Tranform new and updated records.
      # If nothing to do, return nil.
      def process(record)
        ## transform the row into JSON
        return transform_to_new_document_json(record) if @upload_type == INITIAL_UPLOAD_TYPE
        # look at created_at date against last_upload_date to determine
        # whether the standard is new or needs an update
        if record.created_at > @last_upload_date
          transform_to_new_document_json(record)
        elsif record.updated_at > @last_upload_date
          transform_to_updated_document_json(record)
        end
      end

      private def transform_to_new_document_json(record)
        # this transform creates the JSON that
        # creates a new document for the OS index
        # we use the record index as the OS index
        transformation = []
        transformation << { index: { _index: OpenSearchClient.opensearch_stds_index, _id: record.id } }
        transformation << transform_mapped_item(record)
      end

      # the JSON cannot include any lines breaks except one at  the end
      private def transform_to_updated_document_json(record)
        # this transform creates the JSON that
        # updates an existing document in the OpenSearch index
        # the only difference is the first JSON block before
        # the actual document
        transformation = []
        transformation << { update: { _index: OpenSearchClient.opensearch_stds_index, _id: record.id } }
        # then do the actual item
        transformation << { doc: transform_mapped_item(record) }
      end

      private def transform_mapped_item(record)
        # this is where we create the JSON document for the mapped
        # item that includes all its properties and the list of alignments
        # with the properties of each
        @converter.convert(record)
      end
    end
  end
end
