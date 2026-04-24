module Lti
  class StudentDashboardController < ApplicationController
    before_action :require_student
    before_action :require_lti_rostering_user

    def index
      section = Section.find_by!(guid: params[:section_guid])
      params[:section_id] = section.id
      params[:course_id] = section.course.id
      redirect_to course_section_path(section.course, section)
    end
  end
end
