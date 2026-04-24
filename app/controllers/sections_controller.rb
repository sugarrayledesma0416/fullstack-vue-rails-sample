class SectionsController < ApplicationController
  before_action :redirect_to_local_url,
                if: -> { params[:guids].present? && params[:guids] },
                only: :show

  before_action :require_user
  before_action :require_program_access, only: %i[show study_schedule]
  before_action :warn_insufficient_course_access, only: :show, unless: :has_grace_period?
  before_action :archived_program_redirect

  include HasHelp

  before_action :contextual_help_url, except: :weeks_covered

  before_action :protect_from_instructors

  include SectionHeader

  before_action :assign_section_header,
                except: %i[weeks_covered no_section_dashboard_show no_section_calendar_show]

  layout 'music_v1/default',
         only: %i[no_section_dashboard_show show study_schedule]

  def protect_from_instructors
    # Support showing instructors a preview of the student dashboard.
    # If user is an instructor, but query args contain preview=true,
    # don't redirect them.
    return unless current_user.instructor? && params[:preview] != 'true'

    redirect_to instructor_dashboard_path(current_program.id)
  end

  def no_section_dashboard_show
    @menu_location = 'dashboard'
    @message = 'You need to be actively enrolled in a course in order to have a dashboard.'
    @page_title = 'Course Dashboard'
    render 'sections/no_section_show'
  end

  # This is really no_section_student_calendar_show
  def no_section_calendar_show
    @menu_location = 'content'
    @message = 'You need to be actively enrolled in a course in order to have an assignment calendar.'
    render 'sections/no_section_show'
  end

  def no_section_assessments_show
    @message = 'You need to be actively enrolled in a course in order to access assessments.'
    render 'sections/no_section_show'
  end

  def show
    @menu_location = 'dashboard'
    @page_title = 'Dashboard'

    return 'No section' unless current_section

    @section = current_section
    block_maestro_2(current_section)

    @presenter = StudentDashboardPresenter.new(current_user, current_section)

    @course = current_section.course
    @instructor = current_section.instructor
    assign_activity_return_to_url

    # TODO: move to model
    unless current_user.first_dashboard_viewed_at
      current_user.update(first_dashboard_viewed_at: Time.zone.now.to_s(:db))
    end
  end

  # This is really student_calendar_show
  def study_schedule
    return 'No section' unless current_section

    @menu_location = 'content'
    @page_header = 'Calendar'

    block_maestro_2(current_section)
    @calendar_presenter = build_calendar_presenter(params[:month])
    session[:activity_return] = { 'label' => 'Return to Calendar', 'url' => study_schedule_path }
    render :study_schedule
  end

  def weeks_covered
    section = Section.find_by_id(params[:section_id])
    @weeks = section ? section.weeks_covered : []
    render layout: false
  end

  def show_calendar
    @calendar_presenter = build_calendar_presenter(params[:year_month])
    render 'calendar/_event_calendar',
           layout: false,
           locals: { calendar_presenter: @calendar_presenter }
  end

  private def assign_activity_return_to_url
    session[:activity_return] = {
      'label' => 'Return to Dashboard',
      'url' => course_section_path
    }
  end

  private def redirect_to_local_url
    course = Course.by_guid(params[:course_id])
    section_id = Section.by_guid(params[:section_id]).id

    if course.program.supersite_junior?
      redirect_to jr_course_section_url(course_id: course.id, section_id: section_id)
    else
      redirect_to course_section_url(course_id: course.id, section_id: section_id)
    end
  end

  private

  def build_calendar_presenter(month)
    @section = current_section
    @course = @section.course

    calendar_date = month_date(month)
    calendar_presenter = CalendarPresenter.new(current_user, calendar_date, current_program,
                                               { section: @section })
    calendar_presenter.build_calendar
    calendar_presenter
  end

  def month_date(yearmonth)
    if yearmonth
      (year, month) = yearmonth.split('-')
      Date.new(year.to_i, month.to_i, 1)
    else
      Time.zone.now.to_date
    end
  end
end
