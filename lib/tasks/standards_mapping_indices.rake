namespace :standards_mapping_indices do
  desc 'Create index and define the properties of the standard_assets index ' \
       ' in Dev/QA OpenSearch clusters only'
  task define_standard_assets_index: :environment do |task_name|
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end
    open_search_client = StandardsMapping::OpenSearchClient.new()
    if open_search_client.standard_assets_index_exists?
      puts "standard_assets index already exists; to redefine it run the delete rake task and then run this task"
    else
      properties = StandardsMapping::StandardsMappingIndicesHelper.new.read_file('standard_assets_fields_mapping.json')
      open_search_client.define_standard_assets_index_properties(properties)
    end
  rescue StandardError => error
    puts "Defining standard_assets index task reported error #{error.message}"
  end

  desc 'Create index and define the properties of the standard_alignments index ' \
       'in Dev/QA OpenSearch clusters only'
  task define_standard_alignments_index: :environment do
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end
    open_search_client = StandardsMapping::OpenSearchClient.new
    if open_search_client.standard_alignments_index_exists?
      puts "standard_alignments index already exists; to redefine it run the delete rake
            task and then run this task"
    else
      properties = StandardsMapping::StandardsMappingIndicesHelper.new.read_file(
        'standard_alignments_fields_mapping.json'
      )
      open_search_client.define_standard_alignments_index_properties(properties)
    end
  rescue StandardError => e
    puts "Defining standard_alignments index task reported error #{e.message}"
  end

  desc 'Create index and define the properties of the standards index' \
       ' in Dev/QA OpenSearch clusters only'
  task define_standards_index: :environment do |task_name|
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end
    open_search_client = StandardsMapping::OpenSearchClient.new()
    if open_search_client.standard_assets_index_exists?
      puts "standards index already exists; to redefine it run the delete rake task and then run this task"
    else
      properties = StandardsMapping::StandardsMappingIndicesHelper.new.read_file('standards_fields_mapping.json')
      open_search_client.define_standards_index_properties(properties)
    end
  rescue StandardError => error
    puts "Defining standards index task reported error #{error.message}"
  end

  desc 'Delete existing standard_assets_index - convenience method for devs ' \
       'to facilitate redoing the index in Dev/QA envs only'
  task delete_standard_assets_index: :environment do |task_name|
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end
    open_search_client = StandardsMapping::OpenSearchClient.new()
    open_search_client.delete_standard_assets_index
  rescue StandardError => error
    puts "Deleting standard_assets index task reported error #{error.message}"
  end

  desc 'Delete existing standard_alignments_index - convenience method for devs ' \
       'to facilitate redoing the index in Dev/QA envs only'
  task delete_standard_alignments_index: :environment do
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end
    open_search_client = StandardsMapping::OpenSearchClient.new
    open_search_client.delete_standard_alignments_index
  rescue StandardError => e
    puts "Deleting standard_alignments index task reported error #{e.message}"
  end

  desc 'Delete existing standards_index - convenience method for devs ' \
       'to facilitate redoing the index in Dev/QA envs only'
  task delete_standards_index: :environment do |task_name|
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end
    open_search_client = StandardsMapping::OpenSearchClient.new()
    open_search_client.delete_standards_index
  rescue StandardError => error
    puts "Deleting standards index task reported error #{error.message}"
  end

  # PROD rake tasks -NOTE: There is no PROD rake task to delete either index.
  # This would be a fairly drastic step to take in PROD.
  # It should only be considered before the OS cluster is actually loaded
  # with data and in use by VHLCentral.
  # Reasons might be if we made some mistake creating one of the indices
  # or mapping its properties.
  # A qualified Ops person should delete the messed up index via an AWS console
  # if we ever need to do that.
  desc 'Create index and define properties of the standard_assets index ' \
       ' in PROD OpenSearch cluster'
  task define_prod_standard_assets_index: :environment do |task_name|
    if Rails.env.live?
      open_search_client = StandardsMapping::OpenSearchClient.new()
      properties = StandardsMapping::StandardsMappingIndicesHelper.new.read_file('./standard_assets_fields_mapping.json')
      begin
        open_search_client.define_standard_assets_index_properties(properties)
      rescue StandardError => error
        puts "Defining PROD standard_assets index task reported error #{error.message}"
      end
    else
      puts 'This task must be run on a Production server.'
      exit
    end
  end

  desc 'Create index and define properties of the standard_alignments index ' \
       'in PROD OpenSearch cluster'
  task define_prod_standard_alignments_index: :environment do
    if Rails.env.live?
      open_search_client = StandardsMapping::OpenSearchClient.new
      properties = StandardsMapping::StandardsMappingIndicesHelper.new.read_file(
        './standard_alignments_fields_mapping.json'
      )
      begin
        open_search_client.define_standard_alignments_index_properties(properties)
      rescue StandardError => e
        puts "Defining PROD standard_alignments index task reported error #{e.message}"
      end
    else
      puts 'This task must be run on a Production server.'
      exit
    end
  end

  desc 'Create index and define the properties of the standards index' \
       'in PROD OpenSearch cluster'
  task define_prod_standards_index: :environment do |task_name|
    if Rails.env.live?
      open_search_client = StandardsMapping::OpenSearchClient.new()
      properties = StandardsMapping::StandardsMappingIndicesHelper.new.read_file('./standards_fields_mapping.json')
      begin
        open_search_client.define_standards_index_properties(properties)
      rescue StandardError => error
        puts "Defining PROD standards index task reported error #{error.message}"
      end
    else
      puts 'This task must be run on a Production server.'
      exit
    end
  end
end
