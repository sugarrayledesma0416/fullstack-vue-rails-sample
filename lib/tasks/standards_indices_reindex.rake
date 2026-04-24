namespace :standards_indices_reindex do
  desc 'Create an alias for the standards alignment index and point it to the current index (Dev/QA only)'
  task create_standards_alignment_alias: :environment do
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end

    open_search_client = StandardsMapping::OpenSearchClient.new
    alias_name = StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias
    current_index = StandardsMapping::OpenSearchClient.opensearch_std_alignments_index

    # Check if alias already exists
    if open_search_client.alias_exists?(alias_name)
      puts "Alias '#{alias_name}' already exists. No action taken."
    else
      # Ensure index exists before creating alias
      unless open_search_client.standard_alignments_index_exists?
        puts "Index '#{current_index}' does not exist. Please create the index before running this task."
        exit
      end

      open_search_client.create_alias(current_index, alias_name)
      puts "Alias '#{alias_name}' created and pointed to index '#{current_index}'."
    end
  rescue StandardError => error
    puts "Creating alias task reported error: #{error.message}"
  end

  desc 'Delete the alias for the standards alignment index (Dev/QA only)'
  task delete_standards_alignment_alias: :environment do
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end

    open_search_client = StandardsMapping::OpenSearchClient.new
    alias_name = StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias
    current_index = StandardsMapping::OpenSearchClient.opensearch_std_alignments_index

    # Check if alias exists
    if open_search_client.alias_exists?(alias_name)
      # Remove alias from the index
      open_search_client.delete_alias(current_index, alias_name)
      puts "Alias '#{alias_name}' removed from index '#{current_index}'."
    else
      puts "Alias '#{alias_name}' does not exist. No action taken."
    end

  rescue StandardError => error
    puts "Deleting alias task reported error: #{error.message}"
  end

  desc 'Reindex the standards alignment index (Dev/QA only)'
  task reindex_standards_alignment_index: :environment do
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end

    open_search_client = StandardsMapping::OpenSearchClient.new
    alias_name = StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias
    
    unless open_search_client.alias_exists?(alias_name)
      puts "Alias '#{alias_name}' does not exist. No action taken."
      exit
    end
    
    current_index = open_search_client.get_alias_target_index(alias_name)
    current_version = (current_index.match(/v(\d+)$/) { |m| m[1].to_i } || 0)
    new_version = current_version + 1
    
    new_index = "#{StandardsMapping::OpenSearchClient.opensearch_std_alignments_index}_v#{new_version}"

    unless open_search_client.standard_alignments_index_exists?(new_version)
      # Define the new index properties
      open_search_client.define_standard_alignments_index_properties(
        StandardsMapping::StandardsMappingIndicesHelper.new.read_file('./standard_alignments_fields_mapping.json'),
        new_version
      )
      puts "Defined new index '#{new_index}' with properties."
    end

    # Reindex the current index
    response = open_search_client.reindex(current_index, new_index)
    puts "Reindexing started from '#{current_index}' to '#{new_index}' with task ID: #{response["task"]}"

  rescue StandardError => error
    puts "Reindexing task reported error: #{error.message}"
  end

  desc 'Swap alias to point to the latest reindexed standards alignment index (Dev/QA only)'
  task swap_standards_alignment_alias: :environment do
    if Rails.env.live?
      puts 'You cannot run this task on a Production server.'
      exit
    end

    open_search_client = StandardsMapping::OpenSearchClient.new
    alias_name = StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias

    unless open_search_client.alias_exists?(alias_name)
      puts "Alias '#{alias_name}' does not exist. No action taken."
      exit
    end

    current_index = open_search_client.get_alias_target_index(alias_name)
    current_version = (current_index.match(/v(\d+)$/) { |m| m[1].to_i } || 0)
    new_version = current_version + 1
    new_index = "#{StandardsMapping::OpenSearchClient.opensearch_std_alignments_index}_v#{new_version}"

    unless open_search_client.standard_alignments_index_exists?(new_version)
      puts "New index '#{new_index}' does not exist. Run reindexing first or check index name."
      exit
    end

    # swap the alias to point to the new index
    open_search_client.update_aliases(alias_name, current_index, new_index)
    puts "Alias '#{alias_name}' now points to '#{new_index}'."

  rescue StandardError => error
    puts "Alias swap task reported error: #{error.message}"
  end

  ###############################################################################################
  # PROD tasks: These tasks are intended to be run in a production environment.

  desc 'Create an alias for the standards alignment index and point it to the current index'
  task create_prod_standards_alignment_alias: :environment do
    if Rails.env.live?
      open_search_client = StandardsMapping::OpenSearchClient.new
      alias_name = StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias
      current_index = StandardsMapping::OpenSearchClient.opensearch_std_alignments_index
      begin
        if open_search_client.alias_exists?(alias_name)
          puts "Alias '#{alias_name}' already exists. No action taken."
        else
          unless open_search_client.standard_alignments_index_exists?
            puts "Index '#{current_index}' does not exist. Please create the index before running this task."
            exit
          end
          open_search_client.create_alias(current_index, alias_name)
          puts "Alias '#{alias_name}' created and pointed to index '#{current_index}'."
        end
      rescue StandardError => error
        puts "Creating alias task reported error: #{error.message}"
      end
    else
      puts 'This task must be run on a Production server.'
      exit
    end
  end

  desc 'Reindex the standards alignment index'
  task reindex_prod_standards_alignment_index: :environment do
    if Rails.env.live?
      open_search_client = StandardsMapping::OpenSearchClient.new
      alias_name = StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias

      begin
        unless open_search_client.alias_exists?(alias_name)
          puts "Alias '#{alias_name}' does not exist. No action taken."
          exit
        end

        current_index = open_search_client.get_alias_target_index(alias_name)
        current_version = (current_index.match(/v(\d+)$/) { |m| m[1].to_i } || 0)
        new_version = current_version + 1
        new_index = "#{StandardsMapping::OpenSearchClient.opensearch_std_alignments_index}_v#{new_version}"

        unless open_search_client.standard_alignments_index_exists?(new_version)
          # Define the new index properties
          open_search_client.define_standard_alignments_index_properties(
            StandardsMapping::StandardsMappingIndicesHelper.new.read_file('./standard_alignments_fields_mapping.json'),
            new_version
          )
          puts "Defined new index '#{new_index}' with properties."
        end

        # Reindex the current index
        response = open_search_client.reindex(current_index, new_index)
        puts "Reindexing started from '#{current_index}' to '#{new_index}' with task ID: #{response['task']}"

      rescue StandardError => error
        puts "Reindexing task reported error: #{error.message}"
      end
    else
      puts 'This task must be run on a Production server.'
      exit
    end
  end

  desc 'Swap alias to point to the latest reindexed standards alignment index'
  task swap_prod_standards_alignment_alias: :environment do
    if Rails.env.live?
      open_search_client = StandardsMapping::OpenSearchClient.new
      alias_name = StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias

      begin
        unless open_search_client.alias_exists?(alias_name)
          puts "Alias '#{alias_name}' does not exist. No action taken."
          exit
        end

        current_index = open_search_client.get_alias_target_index(alias_name)
        current_version = (current_index.match(/v(\d+)$/) { |m| m[1].to_i } || 0)
        new_version = current_version + 1
        new_index = "#{StandardsMapping::OpenSearchClient.opensearch_std_alignments_index}_v#{new_version}"

        unless open_search_client.standard_alignments_index_exists?(new_version)
          puts "New index '#{new_index}' does not exist. Run reindexing first or check index name."
          exit
        end

        # Swap the alias to point to the new index
        open_search_client.update_aliases(alias_name, current_index, new_index)
        puts "Alias '#{alias_name}' now points to '#{new_index}'."

      rescue StandardError => error
        puts "Swap alias task reported error: #{error.message}"
      end
    else
      puts 'This task must be run on a Production server.'
      exit
    end
  end
end
