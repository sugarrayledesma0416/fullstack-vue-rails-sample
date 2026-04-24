require 'csv'

class QuestionBankTopicParser
  attr_accessor :errors

  def initialize
    self.errors = []
  end

  def filename
    File.join('/tmp', ENV['filename'])
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
      # expecting required name, language and level columns and optional description
      errors << 'File is missing columns.' if csv.first.count < 3

      csv.each.with_index(1) do |row, idx|
        errors << "Row #{idx} is missing a topic name." if row[:name].nil?
        errors << "Row #{idx} is missing a language." if row[:language].nil?
        errors << "Row #{idx} is missing a level." if row[:level].nil?
      end
    end

    errors.empty?
  end

  def import
    CSV.foreach(filename, headers: true, header_converters: :symbol) do |row|
      topic_params = { name: row[:name],
                       description: row[:description],
                       language: row[:language],
                       level: row[:level] }

      begin
        QuestionBankTopic.create!(topic_params)
      rescue StandardError => e
        errors << e
      end
    end
  end
end
