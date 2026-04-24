module Lti
  class GradebookSectionsController < RequireInstructorController
    skip_before_action :assign_course_sections_and_students_from_focus

    def sync_settings
      section = Section.find_by!(guid: params[:section_guid])
      course = section.course

      # This existing method from FocusAssignment module was originally
      # defined with a slightly-too-specific name, but it does exactly
      # what's needed here.
      set_focus_after_creation(course, section: section)

      redirect_to(
        gradebook_engine.course_section_scores_path(
          gradebook_params(course, section)
        )
      )
    end

    private def gradebook_params(course, section)
      {
        course_id: course.id,
        open_lms_sync: true,
        program_id: params[:program_id],
        section_id: section.id
      }
    end
  end
end
