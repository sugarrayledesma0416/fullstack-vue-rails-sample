#  encoding: utf-8
require 'csv'

module CsvReadWrite

  # Accepts csv file path as parameter and returns array of hashes with csv header as keys.
  def self.read(input)
    faster_csv_options = { :headers => true, :skip_blanks => true }
    csv_data = case input
               when Array
                 CSV.new(array_of_arrays_to_string(input), faster_csv_options)
               else
                 CSV.read(input, faster_csv_options)
               end

    csv_data.inject([]) { |a, row| a << row.to_hash.with_indifferent_access }
  end

  # Accepts multi-dimensional array representing csv structure [["first_name","last_name"],["Bob","Jones"]]
  # and to-be-written csv file path.
  def self.write(data, file_path)
    data = convert_hashes_to_arrays(data) if array_of_hashes?(data)
    CSV.open(file_path, 'wb') do |csv|
      data.each { |row| csv << row }
    end
    data
  end

  def self.array_of_arrays_to_string(array_of_arrays)
    array_of_arrays.map { |row| row.join(',') }.join("\r\n")
  end

  def self.array_of_hashes?(data)
    data.instance_of?(Array) && data[0].instance_of?(Hash)
  end

  def self.convert_hashes_to_arrays(data)
    data.inject([]) { |array, hash| array << hash.values }.insert(0, data[0].keys)
  end
end
