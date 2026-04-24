module Policy
  module Course
    class Delete
      attr_accessor :course, :sections, :user

      delegate :owned_by?, :editable?, to: :course

      DELETION_ERROR_MESSAGES = {
        closed_course: 'You cannot delete a closed course.',
        has_sections: 'Courses with sections cannot be deleted. Delete all sections to enable course deletion.',
        ownership: 'You must be the course owner to delete a course.'
      }.freeze

      # @params course [Course instance] Course to be evaluated in order to verify if it's possible to be deleted.
      # @params sections [Array] Sections visible by a given instructor (these are not course.sections)
      # @params user [User instance] User who's trying to delete a course.
      def initialize(course, sections, user)
        self.course = course
        self.sections = sections
        self.user = user
      end

      def denied_message
        DELETION_ERROR_MESSAGES[denied_reason]
      end

      def permit?
        denied_reason.blank?
      end

      private def denied_reason
        return @denied_reason if defined?(@denied_reason)

        @denied_reason =
          if editable?
            if owned_by?(user) && sections.empty?
              nil
            elsif !owned_by?(user)
              :ownership
            else
              :has_sections
            end
          else
            :closed_course
          end
      end
    end
  end
end
