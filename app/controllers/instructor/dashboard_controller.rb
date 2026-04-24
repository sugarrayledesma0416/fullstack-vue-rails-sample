require 'institution_admin/dashboard_controller'

class Instructor::DashboardController < RequireInstructorController
  layout 'music_v1/default'
  include HasHelp
  include ApplicationHelper
  include GradebookHelper
  include ActionView::Helpers::NumberHelper

  before_action :contextual_help_url
  before_action :setup_closed_course_select_assigns, except: %i[
    section_average
    section_and_category_averages
  ]
  before_action :assign_menu_coords
  skip_before_action :assign_course_sections_and_students_from_focus
  skip_before_action :set_current_focus, only: %i[
    section_average
    section_and_category_averages
  ]
  before_action :reset_focus_from_template, except: %i[
    section_average
    section_and_category_averages
  ]

  def index
    @presenter = InstructorDashboardPresenter.new(
      current_user, current_focus, params
    )
    @course = current_focus.course
    @page_title = @presenter.focused_course_closed? ? 'Old Course' : 'Courses'
    @return_to = request.fullpath

    flash.now[:warning] = @presenter.enrollment_warning unless @presenter.enrollment_warning.nil?

    if current_user.one_roster_rostering? && !current_user.lti_rostering?
      OneRoster::CourseSectionCreator.new(nil, current_program, current_user)
                                     .check_and_associate_as_co_instructor
      unless current_user.has_any_course_for?(current_program)
        redirect_to add_one_roster_instructor_courses_path(current_program)
      end
    end
  end

  def section_average
    section = GradebookEngine::Section.find(params[:section_id])
    average = format_as_percent_with_one_decimal(
      GradebookEngine::GradebookAPI.section_average(section: section).to_f
    )
    render json: { section_id: section.id, results: { average: average } }
  end

  def section_and_category_averages
    section = GradebookEngine::Section.find(params[:section_id])
    averages = GradebookEngine::GradebookAPI.section_and_category_averages(section)

    render json: {
      section_id: section.id,
      results: {
        average: format_as_percent_with_one_decimal(averages[:section].to_f),
        category_averages: formatted_category_averages(
          section, averages[:categories]
        )
      }
    }
  end

  private def setup_closed_course_select_assigns
    return unless session[:focus_type] == 'old_courses'

    @closed_courses_selection_dialog = true
    @closed_courses = current_user.closed_courses
  end

  private def assign_menu_coords
    @menu_location = 'dashboard'
  end

  private def formatted_category_averages(section, averages)
    # loop thru all categories to ensure a default value of 0.0
    section.categories.each_with_object({}) do |category, memo|
      value = averages[category.id.to_s]
      memo[category.id.to_s] = value.nil? ? '0.0%' : format_as_percent_with_one_decimal(value.to_f)
    end
  end

  private def reset_focus_from_template
    return if current_focus.nil? || !current_focus.template?

    # course_id and section_id will be nil if no focused course
    focused_course = current_user.courses_and_sections_for_focus(program).keys.first
    course_id = focused_course&.id
    section_id = focused_course&.sections&.first&.id

    session[:focus] = {
      current_program.id => {
        'course_id' => course_id,
        'section_id' => section_id
      }
    }
    @current_focus = Focus.new(current_user, current_program, session[:focus])
  end
end
