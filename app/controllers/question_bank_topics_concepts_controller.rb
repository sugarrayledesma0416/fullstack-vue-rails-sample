class QuestionBankTopicsConceptsController < ApplicationController
  include QuestionBankReturnTo

  before_action :require_user

  layout 'music_v1/default'

  def upload
    @page_title = 'Upload Topic Concept Mappings List'
  end

  def import
    return redirect_to request.referer, notice: 'No file added' if params[:uploaded_file].nil?
    return redirect_to request.referer, notice: 'Only CSV files allowed' unless params[:uploaded_file].content_type == 'text/csv'

    uploaded_file = File.open(params[:uploaded_file])
    errors = validate(uploaded_file)

    if errors.empty?
      CSV.foreach(uploaded_file, headers: true, header_converters: :symbol) do |row|
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
      redirect_to request.referer, notice: 'Topics Imported'
    else
      redirect_to request.referer, notice: "Errors: #{errors}"
    end
  end

  private def validate(file)
    file_data = File.read(file)
    csv = CSV.parse(file_data, headers: true, header_converters: :symbol)
    errors = []

    if csv.count.zero?
      errors << 'File has no data.'
    else
      # only expecting required topic_id and concept_id fields
      errors << 'File is missing columns.' if csv.first.count < 2

      csv.each.with_index(1) do |row, idx|
        errors << "Row #{idx} is missing a topic id." if row[:topic_id].nil?
        errors << "Row #{idx} is missing concept ids." if row[:concept_id].nil?
      end
    end

    errors
  end
end
