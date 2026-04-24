module UpdateStandards
  extend ActiveSupport::Concern

  # pull updated/new Standards from AB;
  # set searchable flag where necessary;
  # return any AB errors
  private def update_all
    error_response = []
    # pull from AB
    stds_processor = StandardsMapping::StandardsProcessor.new
    stds_processor.save_process
    error_response.concat(stds_processor.errors)
    # set searchable false when a standard has
    # no label and no number
    Standard.where(number: '', label: '').in_batches do |std|
      std.update_all searchable: false
      sleep(0.01)
    end
    error_response
  end

  # update Standards in OpenSearch;
  # return any errors
  private def update_search
    helper = StandardsMapping::StandardsMappingIndicesHelper.new(true)
    helper.upload_standards(StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE)
    helper.errors
  end
end
