module Support
  class CourseOwnersController < ApplicationController
    layout 'music_v1/default'

    before_action :require_user
    before_action :initialize_tool_permissions
    before_action :require_valid_instructor
    before_action :set_page_title

    def initialize_tool_permissions
      authorize! :show, Support::CourseOwnersController
      authorize! :update, Support::CourseOwnersController
    end

    def show
      @presenter = Support::CourseOwnerPresenter.new(instructor)
    end

    def update
      # Use unscoped and let the updater handle closed/archived courses.
      course = Course.unscoped.find_by!(
        id: params[:course_id],
        draft: false,
        is_template: false
      )
      new_owner = Instructor.find(params[:new_owner_id])

      updater = CourseOwnerUpdater.new(course, new_owner)
      updater.update

      if updater.errors.present?
        flash[:error] = 'Failed to update the course.'
        @course_name = course.name
        @errors = updater.errors
        @presenter = Support::CourseOwnerPresenter.new(instructor)

        render :show
      else
        flash[:notice] = 'Course successfully updated.'
        redirect_to support_course_owner_path(instructor_guid: instructor.guid)
      end
    end

    private def set_page_title
      @page_title = 'Change Course Owner'
    end

    private def instructor
      @instructor ||= Instructor.find_by!(guid: params[:instructor_guid])
                                .extend(CourseOwnerUtilities)
      @instructor
    end

    private def require_valid_instructor
      unless instructor.allows_rostering_course_transfer?
        flash[:error] = 'Can only change course owner for instructors of the following types:'\
          " #{CourseOwnerUtilities::ALLOWED_TYPES_FOR_TRANSFER}."
        redirect_to "#{UA_URL}/support/user_search/#{instructor.guid}"
      end
    end
  end
end
