module Policy
  module Section
    class BlockEnrollment
      attr_reader :user, :section

      delegate :editable_by?, to: :section, allow_nil: true

      # @params user [User instance] User who's visiting the instructor dashboard.
      # @params sections [Section instance] Section to be blocked from students enrolling into.
      def initialize(user, section = nil)
        @user = user
        @section = section
      end

      def permit?
        can? && editable_by?(user)
      end

      def can?
        !user.clever? && !user.one_roster? && !user.lti_rostering?
      end
    end
  end
end
