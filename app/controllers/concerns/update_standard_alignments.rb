module UpdateStandardAlignments
  extend ActiveSupport::Concern

  private def update_alignments(params)
    @update_errors = []
    @program_id = params['program_id']
    @alignments_processor = StandardsMapping::AlignmentsProcessor.new

    process_alignment_operation(params)
    update_indices
  end

  private def process_alignment_operation(params)
    Rails.logger.info "[UpdateStandardAlignments] process_alignment_operation - Starting alignment operation of type: #{params['import_type']}"
    case params['import_type']
    when 'sync-asset-alignments'
      @alignments_processor.sync_asset_alignments
    when 'import-new-alignments'
      @alignments_processor.import_new_assets
    else
      @alignments_processor.import_updated_alignments(@program_id)
    end

    update_errors(@alignments_processor.errors)
  end

  # update Standard Alignments in OS
  private def update_indices
    Rails.logger.info '[UpdateStandardAlignments] update_indices - Starting update of standard alignments index'
    helper = StandardsMapping::StandardsMappingIndicesHelper.new(true)
    helper.upload_standard_alignments(StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE)

    if @alignments_processor.obsolete_alignments.present?
      helper.delete_standard_alignments(
        obsolete_alignments: @alignments_processor.obsolete_alignments
      )
    end

    update_errors(helper.errors)
  end

  private def update_errors(errors)
    @update_errors.concat(errors)
  end
end
