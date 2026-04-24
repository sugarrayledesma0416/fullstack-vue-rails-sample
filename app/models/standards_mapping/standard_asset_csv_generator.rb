module StandardsMapping
  class StandardAssetCsvGenerator
    ACTIVITY_HEADERS = %w[
      guid
      client_id
      title
      unit_name
      lesson_name
      strand_name
      component_name
      activity_type
      domain
      subdomain
      program_ids
      mapped_item_type
      content_url
      m3_url
      standards_id_list
    ].freeze

    ASSESSMENT_ITEM_HEADERS = %w[
      guid
      client_id
      title
      units
      lessons
      strands
      component_name
      activity_type
      domain
      subdomain
      program_ids
      mapped_item_type
      content_url
      m3_url
      standards_id_list
    ].freeze

    TE_CONTENT_HEADERS = %w[
      guid
      client_id
      title
      page_number
      descriptor
      concept_name
      unit_name
      domain
      subdomain
      program_ids
      mapped_item_type
      content_url
      standards_id_list
    ].freeze

    def initialize(program_id, type)
      @program_id = program_id
      @type = type
    end

    def generate_csv_string
      CSV.generate(write_headers: true, headers: csv_headers) do |csv_data|
        build_csv_rows(asset_rows, csv_data)
      end
    end

    private def csv_headers
      case @type
      when 'te-content'
        TE_CONTENT_HEADERS
      when 'activity'
        ACTIVITY_HEADERS
      else
        ASSESSMENT_ITEM_HEADERS
      end
    end

    private def build_csv_rows(asset_rows, csv_data)
      asset_rows.each do |row|
        csv_data << row
      end
    end

    private def asset_rows
      @asset_rows ||= StandardsMapping::StandardAssetExporter.new(@program_id, @type)
    end
  end
end
