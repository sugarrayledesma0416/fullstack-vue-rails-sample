class ProgramConfigsController < ApplicationController
  before_action :require_user
  load_and_authorize_resource

  layout 'music_v1/default'

  def edit
    @program = Program.find(params[:program_id])
    @programs_by_title ||= programs_by_title
    @program_edition = ProgramEdition.find_by(program_id: params[:program_id])
    @program_config = ProgramConfig.currently_active(@program) || ProgramConfig.new(program: program)
    @presenter = ProgramConfigPresenter.new(@program_config)
    @mapping_presenter = ProgramToProgramMappingPresenter.new(@program)
  end

  # TODO: To improve user experience, we should do one or more of the following:
  #       - Only enable the "Submit" button when config in the UI form differs
  #         from the current program config.
  #       - If the user clicks the "Submit" button without changing anything,
  #         do not attempt to create a new ProgramConfig and display a more user
  #         friendly error message.
  #       - When the user clicks submit and the changes save successfully, help
  #         the user validate their changes by highlighting the changes either
  #         by redirecting to the show page with highlights or adding detail to
  #         the success flash message.
  def update
    @program = Program.find(params[:program_id])

    datastore = params.require(:datastore).permit(
      :allow_assessments_randomization,
      :audio_transcripts,
      :ebook,
      :hide_activities,
      :hide_assessment,
      :hide_my_content,
      :hide_translation,
      :practice_test_analytics_enabled,
      :pronto,
      :question_banks_enabled,
      :pmr_standard_reports_allowed,
      :show_skills_and_refinement_filters,
      :share_to_portfolio,
      :enable_concurrent_enrollment,
      :speech_rec,
      :study_center,
      :teacher_vtext_label,
      :vocab_definition,
      :vocab_tools,
      :vocab_words,
      :vtext_label,
      ai_settings: [
        :grading_suggestions,
        :program_level
      ],
      content_menu_additional_entries: %i[label program_id target_user url description],
      course_setup_descriptions: [
        :express_course,
        :advanced_course,
        learning_tracks: [
          :header,
          :general,
          :options_overall,
          options: %i[label explanation]
        ]
      ],
      settings: %i[label link type],
      standards_settings: [
        :min_grade,
        :max_grade,
        supported_standard_set_ids: []
      ],
      teacher_vtext: %i[url],
      vtext: %i[type url]
    )
    datastore.delete(:vocab_tools) unless params[:vocab_tools_enabled]
    datastore[:vocab_definition] = '' if datastore.key?(:hide_translation)
    @program_config = ProgramConfig.new(
      datastore.merge(
        program_id: @program.id,
        creator_id: current_user.id
      )
    )
    @presenter = ProgramConfigPresenter.new(@program_config)
    @mapping_presenter = ProgramToProgramMappingPresenter.new(@program)
    errors = []
    notices = []

    save_program_to_program_mapping(errors, notices)
    save_program_edition_updates(errors, notices)

    if @program_config.save
      notices << 'New configuration created.'
    elsif @program_config.errors.any?
      errors << @program_config.errors.full_messages.to_sentence
    end

    flash.now[:error] = errors.join(', ') if errors.any?
    flash.now[:notice] = notices.join(', ') if notices.any?
    render :edit
  end

  def show
    @program = Program.find(params[:program_id])
    @program_config = ProgramConfig.currently_active(@program)
  end

  def update_vocab_tools
    program = Program.find(params[:program_id])
    VocabWordsCleaner.clean(params[:program_id], _should_delete = true)
    VocabListV2Extractor.generate_vocabulary_for(program)
    render json: { status: :ok }
  end

  def mapping_source_program
    @presenter = ProgramToProgramMappingPresenter.new
    render json: @presenter.mapping_src_lessons_strands(params[:src_prog])
  end

  def mapping_dest_lesson_strands
    @presenter = ProgramToProgramMappingPresenter.new
    render json: @presenter.mapping_dest_lesson_strands(params[:dest_lesson])
  end

  def remove_existing_mappings
    ProgramToProgramMapping.where(dest_program_id: params[:program_id]).delete_all

    # For the case where the chosen source program is mapped to another destination,
    #  remove the mappings for the other destination as well.
    unless params[:current_dest_for_src].blank?
      ProgramToProgramMapping.where(dest_program_id: params[:current_dest_for_src]).delete_all
    end
    render json: { status: :ok }
  end

  def current_dest_for_src
    @presenter = ProgramToProgramMappingPresenter.new
    render json: @presenter.current_dest_for_src(params[:src_prog])
  end

  def map_automatically
    @presenter = ProgramToProgramMappingPresenter.new
    render json: @presenter.map_automatically(params[:program_id], params[:src_prog_id])
  end

  private def programs_by_title
    @programs_by_title ||= Program.all
                                  .where(is_archived: false, maestro_version: 3)
                                  .order(:title)
                                  .pluck(:id, :title).map { |id, title| { id:, title: } }
  end
  helper_method :programs_by_title

  private def save_program_to_program_mapping(errors, notices)
    # save program to program mapping for IGC copy
    mapping_error = false
    return unless mapping = params[:ptp_mapping]

    mapping.each do |item|
      begin
        m = ProgramToProgramMapping.find_or_initialize_by(
          src_strand_id: item['src_strand_id'],
          dest_program_id: params[:program_id]
        )
        m.dest_strand_id = item['dest_strand_id']
        m.save!
      rescue ActiveRecord::RecordInvalid => e
        mapping_error = true
        errors << e.message
      rescue StandardError => e
        mapping_error = true
        errors << "Unexpected error: #{e.message}"
      end
    end

    if mapping_error
      errors << 'There was an error saving some mappings. '
    else
      notices << 'My Content mapping successful!'
    end
  end

  private def save_program_edition_updates(errors, notices)
    @program_edition = ProgramEdition.find_or_initialize_by(program_id: params[:program_id])
    @program_edition.next_edition_program_id = params[:next_edition_program_id]
    @program_edition.previous_edition_program_id = params[:previous_edition_program_id]

    return unless @program_edition.changed?

    @program_edition.save
    if @program_edition.errors.full_messages.any?
      errors << @program_edition.errors.full_messages.join(', ')
    else
      notices << 'Program editions updated successfully!'
    end
  end
end
