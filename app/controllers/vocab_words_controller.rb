class VocabWordsController < ApplicationController
  include VocabSecurity
  before_action :require_user
  before_action :set_current_focus, if: :current_user_is_instructor?
  before_action :assign_course_sections_and_students_from_focus,
                only: %i[index update],
                if: :current_user_is_instructor?
  before_action { |controller| controller.require_vocab_license('My Vocabulary') }

  # Since this endpoint renders HTML and then calls itself to render JSON,
  # the browser caches the JSON, and incorrectly displays it when the user
  # hits back/forward.
  before_action :set_cache_buster, only: :index

  # GET /vocab_words
  def index
    @page_title = 'My Vocabulary'
    @menu_location = { level_1: 'teaching' }

    begin
      respond_to do |format|
        format.html
        format.json { render json: VocabWord.serialize_to_json_for_student_and_language(current_user, current_program) }
      end
    rescue VocabLicenseError => e
      VHLMonitor.notify(e, rack_env: request.env)
      # When no licenses for vocab words are found, an exception is thrown, preventing a proper
      # response from VocabWord.serialize_to_json_for_student_and_language to be returned.
      # That response needs to be sent for the JS in the view to work properly.
      render json: { activities: [] }.to_json
    end
  end

  # GET /vocab_words/popup
  def index_popup
    respond_to do |format|
      format.html { render action: :index }
    end
  end

  # POST /vocab_words
  def create
    current_program_params = {
      language: current_program.language_code,
      program_id: current_program.id,
      vocab_program_group_id: current_program.vocab_program_group.id
    }
    vocab_word = current_user.vocab_words.build(vocab_word_params.merge(current_program_params))

    respond_to do |format|
      if vocab_word.save
        format.json { render json: vocab_word.to_json(include: :vocab_tags), status: :created }
      else
        format.json { render json: { errors: vocab_word.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # PUT /vocab_words/:id
  def update
    vocab_word = VocabWordUpdater.new(current_user, vocab_word_params).update_vocab_word

    respond_to do |format|
      if vocab_word.errors.empty? && vocab_word.valid?
        format.json { render :json => vocab_word.to_json(:include => :vocab_tags), :status => :created }
      else
        format.json { render :json => { :errors => vocab_word.errors.full_messages }, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /vocab_words/:id
  def destroy
    VocabWordDeleter.new(current_user, params).delete_vocab_word

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def print_pdf
    @study_sheet_type = params[:study_sheet_type]
    @vocab_words = params[:vocab_word_ids].present? ? VocabWord.find(params[:vocab_word_ids]) : []
    @default_vocab_words = params[:default_vocab_word_ids].present? ? DefaultVocabWord.find(params[:default_vocab_word_ids]) : []
    # If we use a respond_to here, we've got to specify the right content type in the submitted form.
    # I got fed up with trying to make that work, so this action always responds with a PDF.
    render :pdf => "study_sheet_#{Time.now.to_f}",
      :template => 'vocab_words/_study_sheets',
      :formats => [:pdf],
      :layout => 'pdf',
      :disposition  => 'attachment',
      :encoding => 'UTF-8'
  end

  private

  def vocab_word_params
    params.require(:vocab_word).permit(
      :_destroy_image,
      :archived,
      :base_word,
      :default_vocab_word_id,
      :id,
      :language,
      :lesson,
      :lesson_id,
      :original_filename,
      :program_id,
      :recording_path,
      :student,
      :target_definition,
      :target_word,
      :temp_file_path,
      :user_id,
      :vocab_program_group_id,
      :vocab_tags_attributes,
    )
  end
end
