require 'csv'

# Reads a csv file, treating the first non-empty line as a header,
# using it as the keyset when building rows.

class CSVHashReader

  CSV::HeaderConverters[:underscore] = lambda { |value| value.strip.underscore.to_sym }
  CSV::Converters[:to_nil_if_null] = lambda { |value| CSVHashReader.to_nil_if_null(value) }

  def initialize(file)
    @reader = CSV.read(
      file,
      headers: true,
      header_converters: [:underscore],
      converters: [:to_nil_if_null]
    )
  end

  def each
    begin
      @reader.each do |row|
        yield(row)
      end
    rescue CSV::MalformedCSVError => e
      raise "illegal CSV format: #{e}"
    end
  end

  def self.to_nil_if_null(value)
    value = value.to_s.strip
    value = nil if value == "NULL" or value.length == 0
    value
  end
end
