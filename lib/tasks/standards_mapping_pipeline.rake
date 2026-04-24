namespace :standards_mapping_pipeline do
  desc 'Run DEV/QA Kiba pipeline to upload standard_assets to OpenSearch'
  task run_standard_assets_job: :environment do |task_name|
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end
    upload_type = ENV["upload_type"]
    unless upload_type && StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
      puts 'USAGE: rake standards_mapping_pipeline:run_standard_assets_job upload_type=<INITIAL|UPDATE>'
      exit
    end
    if StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
      mapping_helper = StandardsMapping::StandardsMappingIndicesHelper.new
      success = true
      error_msg = nil
      job =
        StandardsMapping::Etl::StandardAssetsUploadJob.setup(
          mapping_helper.upload_config_params(StandardsMapping::OpenSearchClient.opensearch_std_assets_index,
                        upload_type.upcase)
        )
      begin
        Kiba.run(job)
      rescue StandardError => e
        mapping_helper.output_error_recovery_info('standard_assets', e)
          success = false
          error_msg = e.message
      end
      mapping_helper.log_upload_status(StandardsMapping::OpenSearchClient.opensearch_std_assets_index, upload_type.upcase, success, error_msg)
    else
      puts "Upload type #{upload_type} UNKNOWN."
      puts 'USAGE: rake standards_mapping_pipeline:run_standard_assets_job upload_type=<INITIAL|UPDATE>'
    end
  end

  desc 'Run DEV/QA Kiba pipeline to upload standards to OpenSearch'
  task run_standards_job: :environment do |task_name|
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end
    upload_type = ENV["upload_type"]
    unless upload_type && StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
      puts 'USAGE: rake standards_mapping_pipeline:run_standards_job upload_type=<INITIAL|UPDATE>'
      exit
    end
    if StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
      mapping_helper = StandardsMapping::StandardsMappingIndicesHelper.new
      success = true
      error_msg = nil
      job =
        StandardsMapping::Etl::StandardsUploadJob.setup(
          mapping_helper.upload_config_params(StandardsMapping::OpenSearchClient.opensearch_stds_index,
                        upload_type.upcase)
        )
      begin
        Kiba.run(job)
      rescue StandardError => e
        mapping_helper.output_error_recovery_info('standards', e)
        success = false
        error_msg = e.message
      end
      mapping_helper.log_upload_status(StandardsMapping::OpenSearchClient.opensearch_stds_index, upload_type.upcase, success, error_msg)
    else
      puts "Upload type #{upload_type} is unknown."
      puts 'USAGE: rake standards_mapping_pipeline:run_standards_job upload_type=<INITIAL|UPDATE>'
    end
  end

  desc 'Run DEV/QA Kiba pipeline to upload standard_alignments to Opensearch'
  task run_standard_alignments_job: :environment do |task_name|
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end
    upload_type = ENV["upload_type"]
    unless upload_type && StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
      puts 'USAGE: rake standards_mapping_pipeline:run_standard_alignments_job upload_type=<INITIAL|UPDATE>'
      exit
    end
    if StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
      mapping_helper = StandardsMapping::StandardsMappingIndicesHelper.new
      success = true
      error_msg = nil
      job =
        StandardsMapping::Etl::StandardAlignmentsUploadJob.setup(
          mapping_helper.upload_config_params(
            StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias,
            upload_type.upcase,
            4000
          )
        )
      begin
        Kiba.run(job)
      rescue StandardError => e
        mapping_helper.output_error_recovery_info('standard_alignments', e)
        success = false
        error_msg = e.message
      end
      mapping_helper.log_upload_status(
        StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias,
        upload_type.upcase,
        success,
        error_msg
      )
    else
      puts "Upload type #{upload_type} is unknown."
      puts 'USAGE: rake standards_mapping_pipeline:run_standard_alignments_job upload_type=<INITIAL|UPDATE>'
    end
  end

  desc 'Run PROD Kiba pipeline to upload standard_assets to OpenSearch'
  task run_prod_standard_assets_job: :environment do |task_name|
    if Rails.env.live?
      upload_type = ENV["upload_type"]
      unless upload_type && StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
        puts 'USAGE: rake standards_mapping_pipeline:run_standard_assets_job upload_type=<INITIAL|UPDATE>'
        exit
      end
      if StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
        mapping_helper = StandardsMapping::StandardsMappingIndicesHelper.new
        success = true
        error_msg = nil
        job =
          StandardsMapping::Etl::StandardAssetsUploadJob.setup(
            mapping_helper.upload_config_params(StandardsMapping::OpenSearchClient.opensearch_std_assets_index,
                          upload_type.upcase)
          )
        begin
          Kiba.run(job)
        rescue StandardError => e
          mapping_helper.output_error_recovery_info('standard_assets', e)
        end
        mapping_helper.log_upload_status(StandardsMapping::OpenSearchClient.opensearch_std_assets_index, upload_type.upcase, success, error_msg)

      else
        puts "Upload type #{upload_type} is unknown."
        puts 'USAGE: rake standards_mapping_pipeline:run_prod_standard_assets_job upload_type=<INITIAL|UPDATE>'
      end
    else
      puts 'This task must be run on a Production server.'
      exit
    end
  end

  desc 'Run PROD Kiba pipeline to upload standards to OpenSearch'
  task run_prod_standards_job: :environment do |task_name|
    if Rails.env.live?
      upload_type = ENV["upload_type"]
      unless upload_type && StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
        puts 'USAGE: rake standards_mapping_pipeline:run_standards_job upload_type=<INITIAL|UPDATE>'
        exit
      end
      if StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
        mapping_helper = StandardsMapping::StandardsMappingIndicesHelper.new
        success = true
        error_msg = nil
        job =
          StandardsMapping::Etl::StandardsUploadJob.setup(
            mapping_helper.upload_config_params(StandardsMapping::OpenSearchClient.opensearch_stds_index,
                          upload_type.upcase)
          )
        begin
          Kiba.run(job)
        rescue StandardError => e
          mapping_helper.output_error_recovery_info('standards', e)
        end
        mapping_helper.log_upload_status(StandardsMapping::OpenSearchClient.opensearch_std_assets_index, upload_type.upcase, success, error_msg)
      else
        puts "Upload type #{upload_type} is unknown."
        puts 'USAGE: rake standards_mapping_pipeline:run_standards_job upload_type=<INITIAL|UPDATE>'
      end
    else
      puts 'This task must be run on a Production server.'
      exit
    end
  end

  desc 'Run PROD Kiba pipeline to upload standard_alignments to OpenSearch'
  task run_prod_standard_alignments_job: :environment do |task_name|
    if Rails.env.live?
      upload_type = ENV["upload_type"]
      unless upload_type && StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
        puts 'USAGE: rake standards_mapping_pipeline:run_standard_alignments_job upload_type=<INITIAL|UPDATE>'
        exit
      end
      if StandardsMapping::Etl::UploadTypes::UPLOAD_TYPES.include?(upload_type.upcase)
        mapping_helper = StandardsMapping::StandardsMappingIndicesHelper.new
        success = true
        error_msg = nil
        job =
          StandardsMapping::Etl::StandardAlignmentsUploadJob.setup(
            mapping_helper.upload_config_params(
              StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias,
              upload_type.upcase,
              4000
            )
          )
        begin
          Kiba.run(job)
        rescue StandardError => e
          mapping_helper.output_error_recovery_info('standard_alignments', e)
          success = false
          error_msg = e.message
        end
        mapping_helper.log_upload_status(
          StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias,
          upload_type.upcase,
          success,
          error_msg
        )
      else
        puts "Upload type #{upload_type} is unknown."
        puts 'USAGE: rake standards_mapping_pipeline:run_standard_alignments_job upload_type=<INITIAL|UPDATE>'
      end
    end
  end
end
