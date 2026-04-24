class Instructor::OldCourseYearsController < RequireInstructorController
  before_action :require_instructor
  before_action :set_current_program
  skip_before_action :set_current_focus, :assign_course_sections_and_students_from_focus

  def index
    @years = []
    5.times do |n|
      prev_year = Time.zone.now.to_date.year - n
      @years << Time.zone.now.to_date.year - n unless prev_year < 2011
    end
    render layout: false
  end

  def show
    @courses_and_sections = current_user.closed_courses_by_program_and_year_with_owned_sections(
      current_program,
      params[:id]
    )
    render layout: false
  end
end
