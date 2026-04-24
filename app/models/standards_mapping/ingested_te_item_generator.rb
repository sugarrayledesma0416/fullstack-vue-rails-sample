module StandardsMapping
  class IngestedTeItemGenerator
    EREADER_ITEMS_HEADERS = %w[
      guid
      title
      page_section
      descriptor
      page_number
      concept_id
    ].freeze

    def self.extracted_data_ereader_items(program_id)
      extracted_data = []
      ereader_items_by_program(program_id).each do |item|
        extracted_data << item.attributes.except('created_at', 'id', 'updated_at')
      end
      extracted_data
    end

    def self.generate_csv(program_id)
     # "\uFEFF" is needed to add BOM to force Excel to realize this file is
     # encoded in UTF-8, so it respects special characters
     # https://stackoverflow.com/questions/30368173/ruby-how-to-generate-csv-files-that-has-excel-friendly-encoding
      CSV.generate("\uFEFF") do |csv_data|
        csv_data << EREADER_ITEMS_HEADERS
        extracted_data_ereader_items(program_id).each do |item|
          csv_data << item.values_at(*EREADER_ITEMS_HEADERS)
        end
        csv_data
      end
    end

    def self.ereader_items_by_program(program_id)
      EReaderItem.joins(:concept).where(concepts: { program_id: })
    end
  end
end
