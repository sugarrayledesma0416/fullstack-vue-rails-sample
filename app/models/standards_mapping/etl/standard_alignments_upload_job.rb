module StandardsMapping
  module Etl
    module StandardAlignmentsUploadJob
      # NOTE: expected params
      #         upload_type = 'inital'|'update'
      #         index_name = 'standard_alignments'
      #         batch_size
      #         last_upload_date (irrelevant for initial upload)
      def setup(config_params)
        Kiba.parse do
          source StandardsMapping::Etl::StandardAlignmentSource, config_params
          transform StandardsMapping::Etl::StandardAlignmentTransform, config_params
          destination StandardsMapping::Etl::BulkUploadDestination, config_params
        end
      end
      module_function :setup
    end
  end
end
