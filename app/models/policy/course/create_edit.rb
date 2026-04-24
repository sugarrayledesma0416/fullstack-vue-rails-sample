module Policy
  module Course
    class CreateEdit
      attr_reader :user

      def initialize(user)
        @user = user
      end

      def allowed_to_create_content_in_course?(course)
        # Instructors are allowed to create content if
        # they are allowed to edit all sections for the focused course
        # or if they are the owner of the course
        return true if user.id == course.owner.id

        sections = SectionInstructor.where(user_id: user.id, section_id: course.sections.ids)
        sections.any? && sections.all?(&:allowed_to_edit_content)
      end

      def permit?(school)
        # Instructors may not create/edit courses at districts.
        !school.district? &&
          # Non-Clever users may not create/edit courses once their school adopts Clever,
          # unless they are LTI rostering users who have since transitioned from Clever.
          # NOTE: This allows them to edit courses created before the transition.
          (user_school_clever_match?(school) || clever_transitioned_lti_user?(school))
      end

      # Determines if the school's Clever status matches the user's Clever status.
      #
      # @param school [School] the school to check
      # @return [Boolean] `true` if the Clever statuses match
      #
      # NOTE: This also returns false for Clever users at non-Clever schools,
      # which should never occur because Clever users are only created at Clever
      # schools and Clever users cannot change their school associations. If it
      # ever happens, it should be considered bad data, and preventing course
      # creation/edit for those users is the correct behavior.
      private def user_school_clever_match?(school)
        school.clever? == user.clever?
      end

      # Determines if the user is an LTI user that transitioned from Clever.
      #
      # @param school [School] the school to check
      # @return [Boolean] `true` if the user is an LTI user that transitioned
      #                   from Clever
      #
      # NOTE: This logic supports LTI rostering platforms with Clever filtering,
      # which requires schools to keep their Clever IDs.
      private def clever_transitioned_lti_user?(school)
        non_clever_user_at_clever_school?(school) &&
        user.lti_rostering_transitioned_from_clever?
      end

      # Determines if the user is a non-Clever user at a Clever school.
      #
      # @param school [School] the school to check
      # @return [Boolean] `true` if the user is a non-Clever user at a Clever school
      private def non_clever_user_at_clever_school?(school)
        !user.clever? && school.clever?
      end
    end
  end
end
