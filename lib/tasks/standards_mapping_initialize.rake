namespace :standards_mapping_initialize do
  desc 'Run in DEV/QA to define indices and upload data to OpenSearch'
  task run_standards_mapping_setup: :environment do |task_name|
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end
    open_search_client = StandardsMapping::OpenSearchClient.new()
    open_search_client.delete_standards_index
    puts 'Deleted existing standards index'
    open_search_client.delete_standard_assets_index
    puts 'Deleted existing standard_assets index'
    open_search_client.delete_standard_alignments_index
    puts 'Deleted existing standard_alignments index'
    mapping_helper = StandardsMapping::StandardsMappingIndicesHelper.new
    properties = mapping_helper.read_file('./standards_fields_mapping.json')
    open_search_client.define_standards_index_properties(properties)
    puts 'Defined standards index'
    properties = mapping_helper.read_file('./standard_assets_fields_mapping.json')
    open_search_client.define_standard_assets_index_properties(properties)
    puts 'Defined standard_assets index'
    properties = mapping_helper.read_file('./standard_alignments_fields_mapping.json')
    open_search_client.define_standard_alignments_index_properties(properties)
    puts 'Defined standard_alignments index'
    open_search_client.create_alias(
      StandardsMapping::OpenSearchClient.opensearch_std_alignments_index,
      StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias
    )
    puts 'Created alias for standard_alignments index'
    mapping_helper.upload_standards(StandardsMapping::Etl::UploadTypes::INITIAL_UPLOAD_TYPE)
    mapping_helper.upload_standard_assets(StandardsMapping::Etl::UploadTypes::INITIAL_UPLOAD_TYPE)
  rescue StandardError => error
    puts "OpenSearch index deletion or creation reported an error #{error.message}"
  end
end
