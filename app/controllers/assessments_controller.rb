class AssessmentsController < ApplicationController
  before_action :require_student
  before_action :set_current_program
  before_action :assign_menu_coords
  before_action :require_program_access
  before_action :ensure_correct_section, if: :current_user_is_student?
  before_action :ensure_component_access
  before_action :archived_program_redirect

  include SectionHeader
  before_action :assign_section_header

  include HasHelp
  before_action :contextual_help_url

  layout 'music_v1/default'

  def index
    @presenter = AssessmentsPresenter.new(current_program, current_section, current_user)
    @page_title = 'Assessments'

    session[:activity_return] = {
      'label' => 'Return to Assessment',
      'url' =>  student_assessments_path(
        program_id: current_program,
        section_id: current_section,
        anchor: 'past_assessments'
      )
    }
  end

  def assign_menu_coords
    @menu_location = 'content'
  end

  private def ensure_correct_section
    return if current_user.has_access_to_section_in_program?(
      current_section, current_program, session
    )

    correct_section = (
      current_user.current_section_in_program(current_program, session) ||
      Section.section_zero
    )

    redirect_to student_assessments_path(current_program, correct_section)
  end

  def ensure_component_access
    program_settings = ProgramSettings.new(current_program)

    unless program_settings.has_assessment?
      flash[:notice] = "This Supersite does not have Assessment content."
      redirect_to course_section_path(current_section.course, current_section)
    end
  end
  private :ensure_component_access
end
