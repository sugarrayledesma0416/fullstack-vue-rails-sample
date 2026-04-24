module StandardsMapping
  module Etl
    module StandardAssetsUploadJob
      # to run this Kiba job, call from rake task or sidekiq worker
      # job = StandardsMapping:Etl::StandardAssetsUploadJob.setup(params)
      # Kiba.run(job)
      # NOTE: expected params
      #         upload_type = 'inital'|'update'
      #         index_name = 'standard_assets|standards'
      #         batch_size
      #         last_upload_date (irrelevant for initial upload)
      def setup(config_params)
        Kiba.parse do
          source StandardsMapping::Etl::StandardAssetSource, config_params
          transform StandardsMapping::Etl::StandardAssetTransform, config_params
          destination StandardsMapping::Etl::BulkUploadDestination, config_params
        end
      end
      module_function :setup
    end
  end
end
