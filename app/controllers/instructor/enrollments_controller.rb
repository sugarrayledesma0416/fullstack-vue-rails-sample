class Instructor::EnrollmentsController < RequireInstructorController
  include ActionView::Helpers::TextHelper

  before_action :block_clever_rostering_users
  after_action :enroll_students_to_portfolio, only: %i[create]

  skip_before_action :set_current_focus, except: :new
  skip_before_action :assign_course_sections_and_students_from_focus
  include HasHelp

  def new
    @return_to = vhl_return_to_sanitizer(params[:return_to])

    @selected_student_ids = params[:selected_student_ids]
    @selected_section = Section.find(params[:selected_section_id]) if params[:selected_section_id]
    @selected_section = Section.find( params[:section][:id]) if params[:section_selector]
    @instructor = current_user
    @sections = current_focus.sections

    @page_header = 'Add Students'

    @selected_section ||= @sections.first
    @selected_section_id = @selected_section.id
    @school = @sections.first.course.school
    results = Maestro::Section.prospective_students(current_program.id,
                                                    @selected_section.guid,
                                                    @instructor.schools.pluck(:guid))
    student_ids = results['student_ids']
    student_ids ||= []
    # need to exclude RA user accounts
    @students = Student.order(:last_name).find(student_ids).reject(&:one_roster?)

    @no_app_shell = true
    @hide_header = true
    render layout: 'application_v3'
  end


  def create
    if !params[:selected_student_ids] || params[:selected_student_ids].empty?
      flash[:error] = 'No students selected'
    else
      raise "no section selected " unless params[:selected_section_id]
      @enroller = MultipleStudentEnroller.new(params).enroll
      @enroller.flash_messages.each_pair do |flash_type, messages|
        flash[flash_type] = messages.join(' ')
      end
    end
    redirect_to(vhl_return_to_sanitizer(params[:return_to]))
  end

  private def enroll_students_to_portfolio
    return unless @enroller.present? && @enroller.results[:success]

    section = Section.find(@enroller.section_id)
    return unless section.course.course_share_to_portfolio?

    Portfolio::EnrollStudentWorker.perform_async(
      @enroller.section_id,
      User.where(id: params[:selected_student_ids]).pluck('username')
    )
  end
end
