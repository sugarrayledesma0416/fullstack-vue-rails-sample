module Policy
  module Course
    module ControllerMethods
      private def selected_school
        School.find(selected_school_id)
      end

      private def selected_school_id
        raise NotImplementedError, 'controllers using Policy::Course must '\
                                   'define a selected_school_id'
      end

      private def require_course_policy_permission
        # If we get into a case where we have no school, we may want to raise
        # an error.  It may be more appropriate to raise it from within the
        # permit? method, however.
        # raise 'School is required to check course management permissions' unless selected_school
        unless course_create_edit_policy.permit?(selected_school)
          redirect_to BestDefaultPath.best_default_path(
            current_user, current_program, current_section, session
          )
        end
      end
    end
  end
end
