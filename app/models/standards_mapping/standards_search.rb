module StandardsMapping
  class StandardsSearch
    include DatadogProcessor
    include TimingEvents

    FILTER_OPTION_PROPERTIES = { unit_id: 'programs.unit_id',
                                 lesson_id: 'programs.lesson_id',
                                 reference_type: 'reference_type' }.freeze
    STDS_QUERY_ERROR_MESSAGE =
      'Standards Search ERROR search_term:%s standard_set_guids:%s status:%s %s.'.freeze
    STD_ASSETS_QUERY_ERROR_MESSAGE =
      'StandardAssets Search ERROR standard_guids:%s program:%s filter:%s status:%s %s.'.freeze
    BROWSE_STDS_QUERY_ERROR_MESSAGE =
      'Browse Standards ERROR standard_set_guids:%s program:%s status:%s %s.'.freeze
    POST_SQL = ''

    # given an array of standard_set guids and a search term (any string),
    # returns an array of hashes in this form for all standards
    # that match the search term/phrase and are within the specified standard sets
    # e.g. {
    #        vendor_guid: '801A9116-7440-11DF-93FA-01FD9CFF4B22',
    #        label: 'Grade Level Statermndard',
    #        name: 'English Language Arts/Literacy',
    #        number:'CCSS.ELA-Literacy.RL.6.1',
    #        description: 'Cite textual evidence to support analysis of text.'
    #        vendor_standard_set_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22'
    #      }
    #  returns [] if no matches
    def search_standards(standard_set_guids, search_term, grades, program_id)
      setup_std_alignments_get
      body = standard_query_json(search_term, standard_set_guids, grades, program_id)
      response = time_event(:standards_search) do
        query(body)
      end
      @results = JSON.parse(response.body).deep_symbolize_keys
      if response.code == '200'
        ddog_dispatch(
          metric: 'standards_assigning.open_search.standards.response_time',
          stats_type: 'gauge',
          role: 'standards_search',
          value: response_time[:standards_search].to_i
        )
        build_standards_results
      else
        # if there is an error in the results from the single term
        # search, we want to append it to the response error message
        # as it contains more details
        results_error = @results[:error][:reason]
        error_message = format(STDS_QUERY_ERROR_MESSAGE,
                               search_term,
                               standard_set_guids.map { |e| "'#{e}'" }.join(', '),
                               response.code,
                               response.message + results_error )
        report_error(error_message)
        error_message
      end
    end

    # given an array of selected standard guids, program id and optional filtering selections,
    # returns an array of standard_assets that are aligned to the specified standards along
    # with all their alignments.
    # Filter options: lesson_id, unit_id, reference_type ('Activity, 'AssessmentItem', TEContent')
    # e.g. filter_options = { unit_id: 123, lesson_id: 567, reference_type: 'Activity' }
    # returns an array of standard_assets with their alignments, an array of standard vendor_guids:
    # e.g. {
    #        standard_asset_id: 3,
    #        reference_type: 'Activity',
    #        reference_id: 238301
    #      }
    # returns [] if no matches
    # Example of filter_options : {:unit_id=>[4325, 4578], :reference_type=>["AssessmentItem", "Activity"]}
    def search_standard_assets(selected_standards_guids, program_id, filter_options = {})
      setup_std_alignments_get
      selected_standards_guids_str = selected_standards_guids.map { |e| "'#{e}'" }.join(', ')

      body = standard_asset_query_json(selected_standards_guids, program_id, filter_options)
      response = time_event(:standard_assets_search) do
        query(body)
      end
      @results = JSON.parse(response.body).deep_symbolize_keys
      if response.code == '200'
        ddog_dispatch(
          metric: 'standards_assigning.open_search.standard_assets.response_time',
          stats_type: 'gauge',
          role: 'standard_assets_search',
          value: response_time[:standard_assets_search].to_i
        )

        if @results[:aggregations][:unique_vendors][:after_key]
          build_standard_assets_results + [@results[:aggregations][:unique_vendors][:after_key]]
        else
          build_standard_assets_results
        end
      else
        error_message = format(STD_ASSETS_QUERY_ERROR_MESSAGE,
                               selected_standards_guids_str,
                               program_id,
                               filter_options,
                               response.code,
                               @results[:error][:reason])
        report_error(error_message)
        error_message
      end
    end

    def browse_standards(standard_set_guids, grades, program_id)
      standards_count = Standard.where(vendor_standard_set_guid: standard_set_guids).count
      setup_std_alignments_get

      body = browse_standards_query_json(standard_set_guids, grades, program_id, standards_count)
      response = time_event(:browse_standards) { query(body) }
      @results = JSON.parse(response.body).deep_symbolize_keys

      if response.code == '200'
        ddog_dispatch(
          metric: 'standards_assigning.open_search.browse_standards.response_time',
          stats_type: 'gauge',
          role: 'browse_standards',
          value: response_time[:browse_standards].to_i
        )
        build_browse_standards_results
      else
        error_reason = @results[:error]&.dig(:reason) || 'Unknown error'
        error_message = format(BROWSE_STDS_QUERY_ERROR_MESSAGE,
                                standard_set_guids.map { |e| "'#{e}'" }.join(', '),
                                program_id,
                                response.code,
                                response.message + " #{error_reason}")
        report_error(error_message)
        raise(StandardError, error_message)
      end
    end

    def query(body)
      request.body = body.to_json
      ssl_connection.request(request)
    end

    private def build_standards_results
      @results[:aggregations][:unique_vendors][:buckets].map do |list|
        std_result = list[:vendor_details][:hits][:hits][0]
        std = std_result[:_source] if std_result
        {
          vendor_guid: std[:vendor_guid],
          label: std[:label],
          name: std[:name],
          number: std[:number],
          description: std[:description],
          vendor_standard_set_guid: std[:vendor_standard_set_guid],
          issuer: std[:issuer],
          display_name: std[:display_name],
          parent: {
            vendor_guid: std[:parent][:vendor_guid],
            label: std[:parent][:label],
            name: std[:parent][:name],
            number: std[:parent][:number],
            description: std[:parent][:description],
            vendor_standard_set_guid: std[:parent][:vendor_standard_set_guid],
            issuer: std[:parent][:issuer],
            display_name: std[:parent][:display_name]
          }
        }
      end
    end

    private def build_standard_assets_results
      @results[:aggregations][:unique_vendors][:buckets].map do |list|
        std_result = list[:vendor_details][:hits][:hits][0]
        std = std_result[:_source] if std_result
        {
          standard_asset_id: std[:standard_asset_id],
          reference_id: std[:standard_asset_reference_id],
          reference_type: std[:standard_asset_reference_type]
        }
      end
    end

    private def build_browse_standards_results
      nodes = {}   # Global lookup: vendor_guid => node
      roots = []   # List of root nodes

      @results[:aggregations][:unique_vendors][:buckets].each do |bucket|
        process_bucket(bucket, nodes, roots)
      end

      sort_tree(roots)
    end

    private def process_bucket(bucket, nodes, roots)
      std_result = bucket.dig(:vendor_details, :hits, :hits, 0, :_source)
      return unless std_result

      parent = process_ancestors(std_result[:ancestors] || [], nodes, roots)
      process_leaf(std_result, parent, nodes, roots)
    end

    private def process_ancestors(ancestors, nodes, roots)
      parent = nil
      ancestors.each do |ancestor|
        node = find_or_initialize_node(nodes, ancestor)
        if parent
          parent[:children] << node unless parent[:children].include?(node)
        else
          roots << node unless roots.include?(node)
        end
        parent = node
      end
      parent
    end

    private def process_leaf(std_result, parent, nodes, roots)
      leaf = find_or_initialize_node(nodes, std_result)
      if parent
        parent[:children] << leaf unless parent[:children].include?(leaf)
      else
        roots << leaf unless roots.include?(leaf)
      end
    end

    private def find_or_initialize_node(nodes, std)
      nodes[std[:vendor_guid]] ||= {
        vendor_guid: std[:vendor_guid],
        label: std[:label],
        name: std[:name],
        number: std[:number],
        description: std[:description],
        children: []
      }
    end

    private def sort_tree(nodes)
      nodes.sort_by! { |node| node[:number].to_s }
      nodes.each { |node| sort_tree(node[:children]) }
      nodes
    end

    private def setup_post
      @http ||= Net::HTTP.new(uri.host, uri.port)
      @request ||= Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
    end

    private def setup_std_alignments_get
      @http ||= Net::HTTP.new(
        std_alignments_phrase_search_uri.host,
        std_alignments_phrase_search_uri.port
      )
      @request ||= Net::HTTP::Get.new(
        std_alignments_phrase_search_uri.request_uri,
        'Content-Type' => 'application/json'
      )
    end

    private def ssl_connection
      @http.use_ssl = true
      # For testing only. Use certificate for validation.
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      @http
    end

    private def request
      # basic_auth is only needed when running opensearch locally
      # (some devs are using docker locally).
      if Rails.application.config.respond_to?(:opensearch_username)
        @request.basic_auth(
          Rails.application.config.opensearch_username,
          Rails.application.config.opensearch_password
        )
      end
      @request
    end

    private def uri
      return @uri if defined? @uri

      @uri = URI.parse("#{Rails.application.config.standards_opensearch_url}/_plugins/_sql/")
    end

    private def std_alignments_phrase_search_uri
      return @std_alignments_phrase_search_uri if defined? @std_alignments_phrase_search_uri

      @std_alignments_phrase_search_uri = URI.parse(
        "#{Rails.application.config.standards_opensearch_url}/" \
        "#{OpenSearchClient.opensearch_std_alignments_alias}/_search/"
      )
    end

    private def report_error(error_message)
      Rails.logger.error(error_message)
      Rollbar.error(error_message)
    end

    private def standard_query_json(search_term, standard_set_guids, grades, program_id)
      {
        query: {
          bool: {
            must: [
              { term: { 'programs.program_id': program_id.to_s } },
              { terms: { vendor_standard_set_guid: standard_set_guids } },
              { terms: { 'grade_levels.grade_level': grades } },
              { term: { searchable: true } }
            ],
            should: [
              { wildcard: { label: "*#{search_term}*" } },
              { wildcard: { name: "*#{search_term}*" } },
              { wildcard: { number: "*#{search_term}*" } },
              { wildcard: { description: "*#{search_term}*" } },
              { match_phrase: { label: search_term } },
              { match_phrase: { name: search_term } },
              { match_phrase: { number: search_term } },
              { match_phrase: { description: search_term } }
            ],
            minimum_should_match: 1
          }
        },
        aggs: {
          unique_vendors: {
            terms: { field: 'vendor_guid', size: 200 },
            aggs: {
              vendor_details: {
                top_hits: {
                  _source: {
                    includes: %w[
                      vendor_guid label name number description
                      vendor_standard_set_guid issuer display_name
                      parent.vendor_guid parent.label parent.name
                      parent.number parent.description
                      parent.vendor_standard_set_guid parent.issuer
                      parent.display_name
                    ]
                  },
                  size: 1
                }
              }
            }
          }
        },
        _source: false,
        size: 0
      }
    end

    private def standard_asset_query_json(selected_stds_guids, program_id, filter_options)
      must_conditions = [
        { term: { 'programs.program_id': program_id } },
        { terms: { 'programs.unit_id': filter_options[:unit_id] } },
        ({ terms: { vendor_guid: selected_stds_guids } } if selected_stds_guids.present?),
        {
          terms: {
            standard_asset_reference_type: build_content_type_conditions(
              filter_options[:selected_content_type]
            )
          }
        },
        { term: { searchable: true } }
      ].compact + additional_skills_refinement_query(filter_options)

      {
        query: {
          bool: {
            must: must_conditions
          }
        },
        aggs: {
          unique_vendors: {
            composite: {
              size: 50, # Number of records per request
              sources: [
                { standard_asset_id: { terms: { field: 'standard_asset_id' } } }
              ],
              after: { standard_asset_id: filter_options[:next_key] } # Cursor for pagination
            },
            aggs: {
              vendor_details: {
                top_hits: {
                  _source: {
                    includes: %w[
                      standard_asset_id standard_asset_reference_id standard_asset_reference_type
                    ]
                  },
                  size: 1
                }
              }
            }
          }
        },
        _source: false,
        size: 0
      }
    end

    private def browse_standards_query_json(standard_set_guids, grades, program_id, limit = 2000)
      {
        query: {
          bool: {
            must: [
              { term: { 'programs.program_id': program_id.to_s } },
              { terms: { vendor_standard_set_guid: standard_set_guids } },
              { terms: { 'grade_levels.grade_level': grades } },
              { term: { searchable: true } }
            ]
          }
        },
        aggs: {
          unique_vendors: {
            terms: { field: 'vendor_guid', size: limit },
            aggs: {
              vendor_details: {
                top_hits: {
                  _source: {
                    includes: %w[
                      vendor_guid label name number description
                      ancestors.vendor_guid ancestors.label ancestors.name
                      ancestors.number ancestors.description
                    ]
                  },
                  size: 1
                }
              }
            }
          }
        },
        _source: false,
        size: 0
      }
    end

    private def additional_skills_refinement_query(filter_options)
      skills_conditions = build_skills_conditions(filter_options[:selected_skills])
      refinements_conditions = build_refinements_conditions(filter_options[:selected_refinements])
      additional_filters = []

      unless skills_conditions.empty?
        additional_filters << { bool: { should: skills_conditions, minimum_should_match: 1 } }
      end

      unless refinements_conditions.empty?
        additional_filters << { bool: { should: refinements_conditions, minimum_should_match: 1 } }
      end
      additional_filters
    end

    private def build_skills_conditions(selected_skills)
      selected_skills&.flat_map do |skill|
        skill.split(',').map do |s|
          s = s.strip
          { wildcard: { standard_asset_domains: "*#{s.downcase}*" } }
        end
      end || []
    end

    private def build_refinements_conditions(selected_refinements)
      selected_refinements&.flat_map do |refinement|
        refinement.split(',').map do |r|
          r = r.strip
          { wildcard: { standard_asset_subdomains: "*#{r.downcase}*" } }
        end
      end || []
    end

    private def build_content_type_conditions(selected_content_type)
      selected_content_type = 'All' if selected_content_type.nil?

      {
        'All' => %w[EReaderItem AssessmentItem Activity],
        'Teacher Edition' => %w[EReaderItem],
        'Assessment' => %w[AssessmentItem],
        'Activity' => %w[Activity]
      }.fetch(selected_content_type, [])
    end
  end
end
