namespace :searchable_standards do
  desc 'Set all standards in database to searchable'
  task set_all_db_standards_searchable: :environment do |_task|
    # Handling for WIDA standards
    processor = StandardsMapping::StandardsProcessor.new

    # Iterate over each vendor_guid in StandardSet where issuer is 'WIDA'
    cumulative_leaf_node_ids = StandardSet.where(
      issuer: 'WIDA'
    ).pluck(
      :vendor_guid
    ).flat_map { |vendor_guid| processor.fetch_leaf_node_child_ids(vendor_guid) }

    Standard.where(searchable: false)
            .where.not(id: cumulative_leaf_node_ids)
            .in_batches do |standards_batch|
      # Filter records based on the additional conditions
      records_to_update = standards_batch.select do |standard|
        (standard.number.present? || standard.label.present?)
      end
      puts "Would update #{records_to_update.size} records in this batch"

      Standard.where(id: records_to_update.map(&:id)).update_all(
        searchable: true,
        updated_at: Time.current
      )
      sleep(0.01)
    end
    puts 'Finished processing standards'
  end

  def run_kiba_pipeline(index, job_class, upload_type)
    return unless StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)

    mapping_helper = StandardsMapping::StandardsMappingIndicesHelper.new
    success = true
    error_msg = nil

    job = job_class.setup(
      mapping_helper.upload_config_params(index, upload_type.upcase)
    )

    begin
      Kiba.run(job)
    rescue StandardError => e
      mapping_helper.output_error_recovery_info(index, e)
      success = false
      error_msg = e.message
    end

    mapping_helper.log_upload_status(index, upload_type.upcase, success, error_msg)
  end

  desc 'Run Kiba pipeline to update standards to OpenSearch'
  task run_standards_job: :environment do |_task|
    run_kiba_pipeline(
      StandardsMapping::OpenSearchClient.opensearch_stds_index,
      StandardsMapping::Etl::StandardsUploadJob,
      'UPDATE'
    )
  end

  desc 'Run Kiba pipeline to update standard_alignments to OpenSearch'
  task run_standard_alignments_job: :environment do |_task|
    run_kiba_pipeline(
      StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias,
      StandardsMapping::Etl::StandardAlignmentsUploadJob,
      'UPDATE'
    )
  end
end
