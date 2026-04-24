module StandardsMapping
  class OpenSearchClient
    # -establishes connection to OpenSearch Client API
    # -knows where to get the credentials;
    # -supports the calls we need to make to create
    # the index, add mapping properties and do the
    # bulk upload.
    # -handles errors
    # Rescues, reports and raises error to caller whose
    # responsibility it is to take appropriate action.
    # ToDo - handle updates

    OS_CLIENT_ERROR_MESSAGE = 'OpenSearch %s returned error: %s.'.freeze

    def self.index_prefix
      return '' if Rails.env.live? || Rails.env.production?

      @index_prefix ||= "#{Socket.gethostname}_".downcase
    end

    def self.opensearch_stds_index
      "#{index_prefix}standards"
    end

    def self.opensearch_std_assets_index
      "#{index_prefix}standard_assets"
    end

    def self.opensearch_std_alignments_index
      "#{index_prefix}standard_alignments"
    end

    def self.opensearch_std_alignments_alias
      "#{index_prefix}standard_alignments_alias"
    end

    def bulk_upload(request_body)
      # check whether or not we have a request body;
      # if there is nothing to upload we want to do nothing
      return if request_body.empty?

      # do POST request to bulk load items to one of the indices
      open_search_client.bulk(body: request_body, refresh: true)
    rescue OpenSearch::Transport::Transport::Error => e
      Rails.logger.error { "OpenSearch bulk_upload batch that failed: #{request_body}" }
      report_error('bulk_upload', e)
      raise e
    end

    def standard_assets_index_exists?
      index_exists?(self.class.opensearch_std_assets_index)
    end

    def standard_alignments_index_exists?(index_version = 0)
      index_name = if index_version.positive?
                     "#{self.class.opensearch_std_alignments_index}_v#{index_version}"
                   else
                     self.class.opensearch_std_alignments_index
                   end

      index_exists?(index_name)
    end

    def standards_index_exists?
      index_exists?(self.class.opensearch_stds_index)
    end

    def define_standard_assets_index_properties(properties)
      define_index_properties(self.class.opensearch_std_assets_index, properties)
    end

    def define_standard_alignments_index_properties(properties, index_version = 0)
      index_name = if index_version.positive?
                     "#{self.class.opensearch_std_alignments_index}_v#{index_version}"
                   else
                     self.class.opensearch_std_alignments_index
                   end

      define_index_properties(index_name, properties)
    end

    def define_standards_index_properties(properties)
      define_index_properties(self.class.opensearch_stds_index, properties)
    end

    def delete_standards_index
      delete_index(self.class.opensearch_stds_index)
    end

    def delete_standard_assets_index
      delete_index(self.class.opensearch_std_assets_index)
    end

    def delete_standard_alignments_index
      delete_index(self.class.opensearch_std_alignments_index)
    end

    def alias_exists?(alias_name)
      with_error_handling("alias_exists: #{alias_name}") do
        open_search_client.indices.exists_alias(name: alias_name)
      end
    end

    def create_alias(index, alias_name)
      with_error_handling("create alias: #{alias_name}") do
        open_search_client.indices.put_alias(index:, name: alias_name)
      end
    end

    def delete_alias(index, alias_name)
      with_error_handling("delete alias: #{alias_name}") do
        open_search_client.indices.delete_alias(index:, name: alias_name)
      end
    end

    def get_alias_target_index(alias_name)
      with_error_handling("get alias target index: #{alias_name}") do
        open_search_client.indices.get_alias(name: alias_name).keys.first
      end
    end

    def reindex(from_index, to_index)
      with_error_handling("reindex from: #{from_index} to: #{to_index}") do
        open_search_client.reindex(
          body: {
            source: {
              index: from_index
            },
            dest: {
              index: to_index
            }
          },
          refresh: true,
          slices: 'auto',
          wait_for_completion: false
        )
      end
    end

    def update_aliases(alias_name, old_index, new_index)
      with_error_handling("update aliases: #{alias_name}") do
        open_search_client.indices.update_aliases(
          body: {
            actions: [
              { remove: { index: old_index, alias: alias_name } },
              { add: { index: new_index, alias: alias_name } }
            ]
          }
        )
      end
    end

    private def open_search_client
      # http and transport params are only needed when running opensearch locally
      # (some devs are using docker locally).
      client_params = {
        host: Rails.application.config.standards_opensearch_url
      }.merge(
        if Rails.application.config.respond_to?(:opensearch_username)
          {
            http: {
              scheme: 'https',
              user: Rails.application.config.opensearch_username,
              password: Rails.application.config.opensearch_password
            }
          }
        else
          {}
        end
      ).merge(
        if Rails.application.config.respond_to?(:opensearch_username)
          { transport_options: { ssl: { verify: false } } }
        else
          {}
        end
      )

      @open_search_client ||= OpenSearch::Client.new(client_params)
    end

    # The only update for properties is to add a new one;
    # anything else such has changing a property type requires a new
    # index to be built. So we need them defined correctly from the
    # start.
    private def define_index_properties(index_name, properties)
      create_index(index_name)
      # if we got to here then the index creation was successful;
      # go ahead and define the index mapping properties
      open_search_client.indices.put_mapping(
        index: index_name,
        body: properties
      )
    rescue OpenSearch::Transport::Transport::Error => e
      report_error("properties mapping for index: #{index_name}", e)
      raise e
    end

    private def delete_index(index_name)
      # check for existence before trying to delete the
      # index. This avoids an OpenSearch error.
      open_search_client.indices.delete(index: index_name) if index_exists?(index_name)
    rescue OpenSearch::Transport::Transport::Error => e
      # report any failure from OpenSearch
      report_error("delete index: #{index_name}", e)
      raise e
    end

    private def number_of_shards
      Rails.application.config.opensearch_num_shards
    end

    private def number_of_replicas
      Rails.application.config.opensearch_num_replicas
    end

    private def create_index(index_name)
      # create the index first;
      # 1 shard and 1 replica for test/dev purposes
      index_body = {
        settings: {
          index: {
            number_of_shards:,
            number_of_replicas:
          },
          analysis: {
            normalizer: {
              lowercase_normalizer: {
                type: 'custom',
                filter: ['lowercase']
              }
            }
          }
        }
      }
      open_search_client.indices.create(
        index: index_name,
        body: index_body
      )
    rescue OpenSearch::Transport::Transport::Error => e
      # if create index fails do not try to add mapping properties
      # raise it back to the caller
      report_error("create index: #{index_name}", e)
      raise e
    end

    private def report_error(operation, error)
      error_message = format(OS_CLIENT_ERROR_MESSAGE, operation, error.message)
      Rails.logger.error(error_message)
      Rollbar.error(error_message)
    end

    private def index_exists?(index_name)
      open_search_client.indices.exists?(index: index_name)
    end

    private def with_error_handling(context)
      yield
    rescue OpenSearch::Transport::Transport::Error => e
      report_error(context, e)
      raise e
    end
  end
end
