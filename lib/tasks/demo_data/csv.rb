require_relative 'csv_hash_reader'

module DemoData
  module CSV
    def self.rows(csv_filepath_or_csv_data, is_csv_data = false, &block)
      file = if is_csv_data
               temp_file = Tempfile.new('for_s3_resources.csv')
               temp_file.write(csv_filepath_or_csv_data)
               temp_file.close
               temp_file
             else
               File.open(csv_filepath_or_csv_data, 'r')
             end
      @reader = CSVHashReader.new(file)
      @reader.each do |row|
        yield row
      end
    ensure
      if is_csv_data
        file.close
        file.unlink
      end
    end
  end
end
