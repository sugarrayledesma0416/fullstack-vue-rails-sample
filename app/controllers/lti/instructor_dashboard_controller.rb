module Lti
  class InstructorDashboardController < Instructor::DashboardController
    before_action :require_lti_rostering_user

    def index
      section = Section.find_by!(guid: params[:section_guid])
      set_focus_after_creation(section.course, section: section)
      # TODO - will probably need a presenter specifically for
      # Lti Rostering courses - e.g. no Add Course links, and more
      @presenter = InstructorDashboardPresenter.new(
        current_user, current_focus, params
      )
      @page_title = @presenter.focused_course_closed? ? 'Old Course' : 'Courses'
      @return_to = request.fullpath
    end
  end
end
