class QuestionBankTopicsController < ApplicationController
  include QuestionBankReturnTo

  before_action :require_user
  load_and_authorize_resource
  before_action :assign_return_to, only: %i[show topic_mappings]

  layout 'music_v1/default'

  def index
    @page_title = 'Question Bank Topics'
    @question_bank_topics.order!(:name)
    @languages = @question_bank_topics.map do |question_bank_topic|
      question_bank_topic.language&.downcase
    end.uniq
    @levels = @question_bank_topics.map do |question_bank_topic|
      question_bank_topic.level&.downcase
    end.uniq
  end

  def new
    @page_title = 'New Topic'
  end

  def create
    @question_bank_topic = QuestionBankTopic.create(question_bank_topic_params)

    if @question_bank_topic
      flash[:notice] = 'The topic was successfully created'
      redirect_to question_bank_topic_path(id: @question_bank_topic.id)
    else
      flash.now[:error] = 'Could not create the topic'
      render :new
    end
  end

  def show
    @page_title = "Topic: #{@question_bank_topic.name}".html_safe

    # active banks have a status of 'live' or 'pending'
    # inactive banks have a status of 'archived' or 'rejected'
    @active_banks, @inactive_banks = @question_bank_topic.question_banks.partition do |entry|
      entry.question_bank_revisions.where(status: %w[live pending]).exists?
    end
  end

  def edit
    @page_title = "Editing Topic: #{@question_bank_topic.name}".html_safe

    @topic = QuestionBankTopic.find(params[:id])
  end

  def update
    if @question_bank_topic.update(question_bank_topic_params)
      flash[:notice] = 'The topic was successfully modified'
      redirect_to question_bank_topic_path(id: @question_bank_topic.id)
    else
      flash.now[:error] = 'Could not modify the topic'
      render :edit
    end
  end

  def concept_download
    @page_title = 'Download Concept IDs'
  end

  def concepts_csv
    respond_to do |format|
      format.csv { send_data concepts_file(params), filename: "#{params[:program_id]}-concepts-#{Time.zone.today}.csv" }
    end
  end

  def topic_download
    @page_title = 'Download Topic IDs'

    @languages = @question_bank_topics.map do |question_bank_topic|
      question_bank_topic.language&.downcase
    end.uniq

    @levels = @question_bank_topics.map do |question_bank_topic|
      question_bank_topic.level&.downcase
    end.uniq
  end

  def topics_csv
    respond_to do |format|
      format.csv { send_data topics_file(params), filename: "topics-#{Time.zone.today}.csv" }
    end
  end

  def upload
    @page_title = 'Upload Topic List'
  end

  def import
    return redirect_to request.referer, notice: 'No file added' if params[:uploaded_file].nil?
    return redirect_to request.referer, notice: 'Only CSV files allowed' unless params[:uploaded_file].content_type == 'text/csv'

    uploaded_file = File.open(params[:uploaded_file])
    errors = validate(uploaded_file)

    if errors.empty?
      CSV.foreach(uploaded_file, headers: true, header_converters: :symbol) do |row|
        topic_params = { name: row[:name],
                         description: row[:description],
                         language: row[:language],
                         level: row[:level] }

        QuestionBankTopic.find_or_create_by!(topic_params)
      end
      redirect_to request.referer, notice: 'Topics Imported'
    else
      redirect_to request.referer, notice: "Errors: #{errors}"
    end
  end

  def topic_mappings
    @page_title = "Concept Mappings For: #{@question_bank_topic.name}".html_safe
    @mappings = QuestionBankTopicsConcept.joins(concept: :program)
                                         .where(question_bank_topic_id: @question_bank_topic.id)
                                         .order('programs.title')
  end

  private def validate(file)
    file_data = File.read(file)
    csv = CSV.parse(file_data, headers: true, header_converters: :symbol)
    errors = []

    if csv.count.zero?
      errors << 'File has no data.'
    else
      # only expecting required name and optional description, language and level fields
      errors << 'File is missing columns.' if csv.first.count < 3

      csv.each.with_index(1) do |row, idx|
        errors << "Row #{idx} is missing a topic name." if row[:name].nil?
        errors << "Row #{idx} is missing a language." if row[:language].nil?
        errors << "Row #{idx} is missing a level." if row[:level].nil?
      end
    end

    errors
  end

  private def topics_file(params)
    attributes = %w[name id]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      topics = QuestionBankTopic.where(language: params[:language], level: params[:level]).all

      topics.each do |topic|
        csv << attributes.map { |attr| topic.send(attr) }
      end
    end
  end

  private def concepts_file(params)
    program = Program.find params[:program_id]
    attributes = %w[concept_id concept_name lesson_name program]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      program.concepts.each do |concept|
        csv << [concept.id, concept.name.gsub(',', ''), concept.lesson.name.gsub(',', ''), program.title.gsub(',', '')]
      end
    end
  end

  private def question_bank_topic_params
    params.require(:question_bank_topic).permit(
      :name,
      :language,
      :level
    )
  end
end
