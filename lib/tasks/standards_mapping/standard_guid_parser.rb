require 'csv'

class StandardGuidParser
  attr_accessor :errors

  def initialize
    self.errors = []
  end

  def filename
    ENV['filename']
  end

  def row_count
    CSV.read(filename, headers: true).count
  end

  def validate
    file_data = File.read(filename)
    csv = CSV.parse(file_data, headers: true, header_converters: :symbol)

    if csv.count.zero?
      errors << 'File has no data.'
    else
      # only expecting required guid and optional standard_set headers
      errors << 'File is missing columns.' if csv.first.count < 1

      csv.each.with_index(1) do |row, idx|
        errors << "Row #{idx} is missing a guid." if row[:guid].nil?
      end
    end

    errors.empty?
  end

  def import
    CSV.foreach(filename, headers: true, header_converters: :symbol) do |row|
      Standard.where(vendor_guid: row[:guid]).update(searchable: false)
    rescue StandardError => e
      errors << e
    end
  end
end
