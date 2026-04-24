module Lti
  class ResourceLinkRedirect
    include Rails.application.routes.url_helpers

    attr_accessor :params, :section_id, :user

    def initialize(params, section_id, user)
      self.params = params
      self.section_id = section_id
      self.user = user
    end

    def url
      if for_student_dashboard?
        course_section_path(dashboard_params)
      else
        section_activity_path(id: params[:activity_id], section_id: section_id)
      end
    end

    private def for_student_dashboard?
      params[:view] == 'dashboard'
    end

    # section_id will be 0 if user is an instructor, so the section_guid
    # param is used to look up section records.
    private def section
      Section.find_by!(guid: params[:section_guid])
    end

    private def dashboard_params
      { course_id: section.course_id, section_id: section.id }.tap do |memo|
        memo[:preview] = 'true' if user.instructor?
      end
    end
  end
end
