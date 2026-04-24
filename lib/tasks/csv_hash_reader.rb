require 'csv'

# Reads a csv file, treating the first non-empty line as a header, using it as the keyset when building rows.
class CSVHashReader
  def initialize(file)
    @reader = CSV::Reader.create(file)
    read_header
  end

  def each
    begin
      @reader.each do |row|
        @line_number+= 1
        @current_row = to_hash(@header, row)
        yield(@current_row)
      end
    rescue CSV::IllegalFormatError => e
      raise "illegal CSV format on line: #{@line_number + 1}"
    end
  end

  def current_row
    @current_row
  end

  def line_number
    @line_number
  end

  def header
    @header
  end

  private

  def read_header
    @line_number = 0
    @reader.each do |@header|
      @line_number+= 1
      if @header.length >= 1
        @header.to_a.map! {|column| column.strip.underscore.to_sym}
        break
      end
    end
  end
  
  def to_hash(header, row)
    row_assoc = {}
    index = 0
    header.each do |column|
      value = nil
      if index < row.length
        value = row[index]
        value = value.to_s if value.class == CSV::Cell
        if value.class == String
          value.strip!
          value = nil if value == "NULL" or value.length == 0
        end
      end
      row_assoc[column] = value
      index+= 1
    end
    row_assoc
  end
end
