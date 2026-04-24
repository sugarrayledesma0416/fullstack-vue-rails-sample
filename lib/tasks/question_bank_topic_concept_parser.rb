require 'csv'

class QuestionBankTopicConceptParser
  attr_accessor :csv_file, :errors

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
      # required columns are topic_id and concept_id
      errors << 'File is missing columns.' if csv.first.count < 2

      csv.each.with_index(1) do |row, idx|
        errors << "Row #{idx} is missing a topic id" if row[:topic_id].nil?
        errors << "Row #{idx} is missing a concept id" if row[:concept_id].nil?
      end
    end

    errors.empty?
  end

  def import
    CSV.foreach(filename, headers: true, header_converters: :symbol) do |row|
      topic_id = row[:topic_id]
      string_concept_ids = row[:concept_id]

      concept_ids = string_concept_ids.split(';')

      begin
        topic = QuestionBankTopic.find(topic_id)
        topic.concepts << Concept.find(concept_ids)
      rescue StandardError => e
        errors << e
      end
    end
  end
end
