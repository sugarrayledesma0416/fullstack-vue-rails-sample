module StandardsMapping
  class StandardsMappingIndicesHelper
    attr_accessor :errors

    def initialize(should_log = false)
      @should_log = should_log
      @errors = []
    end

    def upload_standards(upload_type)
      upload_to_index(StandardsMapping::OpenSearchClient.opensearch_stds_index,
                      upload_type,
                      StandardsMapping::Etl::StandardsUploadJob)
    end

    def upload_standard_assets(upload_type)
      Rails.logger.info "[StandardsMapping::StandardsMappingIndicesHelper] upload_standard_assets - Starting upload of standard assets to OpenSearch with upload type: #{upload_type}"
      upload_to_index(
        StandardsMapping::OpenSearchClient.opensearch_std_assets_index,
        upload_type,
        StandardsMapping::Etl::StandardAssetsUploadJob
      )
    end

    def upload_standard_alignments(upload_type)
      Rails.logger.info "[StandardsMapping::StandardsMappingIndicesHelper] upload_standard_alignments - Starting upload of standard alignments to OpenSearch with upload type: #{upload_type}"
      upload_to_index(
        StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias,
        upload_type,
        StandardsMapping::Etl::StandardAlignmentsUploadJob,
        1000
      )
    end

    def upload_to_index(index_name, upload_type, job_class, batch_size = 100)
      Rails.logger.info "[StandardsMapping::StandardsMappingIndicesHelper] upload_to_index - Uploading to index: #{index_name} with upload type: #{upload_type} using job class: #{job_class}"
      success = true
      error_msg = nil
      etl_job =
        job_class.setup(
          upload_config_params(index_name, upload_type, batch_size)
        )
      begin
        Kiba.run(etl_job)
      rescue StandardError => e
        output_error_recovery_info(index_name, e)
        success = false
        error_msg = "#{index_name.capitalize} OpenSearch upload caused an error: #{e}"
        output_msg(error_msg)
        errors << error_msg
      end
      log_upload_status(index_name, upload_type, success, error_msg)
    end

    def upload_config_params(index_name, upload_type, batch_size = 100)
      last_upload_date = upload_type == StandardsMapping::Etl::UploadTypes::INITIAL_UPLOAD_TYPE ?
                           default_date : last_successful_upload_date(index_name)
      output_msg(puts "Using last_upload_date of #{last_upload_date}")
      Rails.logger.info "[StandardsMapping::StandardsMappingIndicesHelper] upload_config_params - Preparing upload config params for index: #{index_name}, upload type: #{upload_type}, batch size: #{batch_size}, last upload date: #{last_upload_date}"
      {
        upload_type: upload_type,
        index_name: index_name,
        # based on max size of POST body and the average size of a StandardAsset
        # with 4 or 5 alignments I ballparked batch size to be 100. It is conservative
        # but we don't want any failures because we are sending too big a request.
        # TODO discuss whether or not we want to make batch size an input parameter
        # to the rake tasks in the future
        batch_size: batch_size,
        last_upload_date: last_upload_date
      }
    end

    def output_error_recovery_info(index, error)
      output_msg("ABORTING #{index} UPLOAD IN #{Rails.env.upcase}.")
      output_msg("ERROR: #{error.message}")
      output_msg('Errors have been logged in both the Rails log and the standards_mapping_upload_statuses table.')
      output_msg('500 errors probably need a code fix.')
      output_msg('OpenSearch errors can indicate either a catastrophic error or an individual batch failure.')
      output_msg('If an individual batch failed, it is probably a data issue. ')
      output_msg('Either bad or unexpected data encountered.')
      output_msg('The failed batch request is logged in the Rails log.')
      output_msg('After the fix is made you can rerun the upload and catch any batches that failed.')
      output_msg(' 1) Investigate the error: check Rails logs and latest record in the')
      output_msg(' standards_mapping_upload_statuses table ')
      output_msg(' 2) Implement a fix: data or code ')
      output_msg(' 3) rerun this task: rake standards_mapping_pipeline:run_#{index}_job upload_type=initial/update ')
    end

    def log_upload_status(index_name, upload_type, success, error_msg)
      Rails.logger.info "[StandardsMapping::StandardsMappingIndicesHelper] log_upload_status - Logging upload status for index: #{index_name}, upload type: #{upload_type}, success: #{success}, error_msg: #{error_msg}"
      log_entry = StandardsMappingUploadStatus.new(index_name: index_name,
                                                   upload_type: upload_type,
                                                   successful: success,
                                                   uploaded_at_date: DateTime.now,
                                                   upload_errors: error_msg)
      log_entry.save!
    end

    def last_successful_upload_date(index_name)
      last_date = StandardsMappingUploadStatus.last_successful_upload_date(index_name)

      if last_date.nil? &&
         index_name == StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias
        # if there is no last successful upload date for standard alignments alias,
        # use the index name directly.
        last_date = StandardsMappingUploadStatus.last_successful_upload_date(
          StandardsMapping::OpenSearchClient.opensearch_std_alignments_index
        )
      end

      output_msg("LAST SUCCESSFUL UPLOAD DATE #{last_date}")
      if last_date.nil?
        # go with default date; this will upload everything.
        # This will create/update any items that failed during the
        # last failed uplaad.
        # uploading any item more than once will update it and
        # increment the version.
        output_msg('Using default')
        last_date = default_date
      end
      output_msg("Using date of #{last_date}")
      last_date
    end

    def default_date
      DateTime.now - 1.year
    end

    def read_file(filename)
      File.read(File.join(__dir__, filename))
    end

    def delete_standard_alignments(obsolete_alignments:)
      output_msg("Deleting obsolete alignments: #{obsolete_alignments.count}")
      return output_msg('No obsolete alignments to delete.') if obsolete_alignments.blank?

      open_search_client = StandardsMapping::OpenSearchClient.new
      failed_ids = []

      process_alignment_batches(obsolete_alignments, open_search_client, failed_ids)

      success = failed_ids.empty?
      error_msg = nil

      if failed_ids.any?
        error_msg = "Failed to delete alignments with IDs: #{failed_ids.join(', ')}"
      end
      
      output_msg(error_msg || 'All obsolete alignments deleted successfully.')

      log_upload_status(
        StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias,
        'DELETE',
        success,
        error_msg
      )
    end

    private def process_alignment_batches(obsolete_alignments, open_search_client, failed_ids)
      delete_document = []

      obsolete_alignments.each do |alignment|
        delete_document << {
          delete: {
            _index: StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias,
            _id: alignment.id
          }
        }

        if delete_document.length >= 100
          failed_ids.concat(process_bulk_deletion(open_search_client, delete_document))
          delete_document.clear
        end
      end

      # Process remaining docs
      failed_ids.concat(process_bulk_deletion(open_search_client,
                                              delete_document)) if delete_document.any?
    end

    private def process_bulk_deletion(client, delete_document)
      return [] if delete_document.empty?

      begin
        client.bulk_upload(delete_document)
        output_msg("Deleted #{delete_document.length} obsolete alignments.")
        []
      rescue StandardError => e
        output_msg("Error deleting obsolete alignments: #{e.message}")
        errors << "Error deleting obsolete alignments: #{e.message}"
        delete_document.map { |doc| doc[:delete][:_id] }
      end
    end

    private def output_msg(msg)
      if @should_log
        Rails.logger.info msg
      else
        puts msg
      end
    end
  end
end
