module StandardsMapping
  class CsvGenerator
    ACTIVITY_HEADERS = %w[
      program_ids
      program_title
      unit_name
      lesson_name
      strand_name
      component_name
      activity_title
      cms_activity_id
      activity_type
      activity_link
      domain
      subdomain
      standards_id_list
    ].freeze

    def initialize(program_id, type)
      @program_id = program_id
      @type = type
      @filename = Program.find(program_id).title.parameterize(separator: '_')
    end

    def generate!
      CSV.open(filepath, 'wb', write_headers: true, headers: ACTIVITY_HEADERS) do |csv_data|
        build_csv_rows(activity_rows, csv_data)
      end
    end

    def generate_csv_string
      CSV.generate(write_headers: true, headers: ACTIVITY_HEADERS) do |csv_data|
        build_csv_rows(activity_rows, csv_data)
      end
    end

    def filepath
      "/tmp/#{@filename}-#{@type.downcase.pluralize}.csv"
    end

    private def activity_rows
      @activity_rows ||= StandardsMapping::ActivitySet.new(@program_id, @type)
    end

    private def build_csv_rows(activity_rows, csv_data)
      activity_rows.each do |row|
        csv_data << row
      end
    end
  end
end
