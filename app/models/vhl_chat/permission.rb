module VhlChat
  class Permission
    def initialize(user, program, access_guardian = nil, section = nil)
      @user = user
      @program = program
      @section = section
      @access_guardian = access_guardian || AccessGuardian.new(user, program)
    end

    # Live Chat is accessible for:
    # - instructors who have a live chat license
    # - students who have live chat enabled in their current course and
    #   have a live chat license.
    def user_can_access_live_chat?
      (@user.instructor? || live_chat_enabled?) && @access_guardian.has_live_chat?
    end

    # Test that live chat is enabled for the current course. If there is
    # no current section or that section is section zero then false is
    # returned.
    def live_chat_enabled?
      valid_section? && @section.course.live_chat_enabled?
    end

    # Partner Chat is accessible for:
    # - instructors who have a live chat license
    # - students who have partner chat enabled in their current course and
    #   have a live chat license.
    def user_can_access_partner_chat?
      (@user.instructor? || partner_chat_enabled?) && @access_guardian.has_live_chat?
    end

    def partner_chat_enabled?
      valid_section? && @section.course.partner_chat_enabled?
    end

    def chat_course_id
      if @user.instructor?
        nil
      else
        @section.try(:course_id)
      end
    end

    def chat_section_id
      if @user.instructor?
        0
      else
        @section.id
      end
    end

    def chat_permissions
      # We don't respect the chat level course settings
      # for instructors, because instructor chat rosters include
      # all courses across all programs. Because of this,
      # the product decision is to turn chat on all the time.
      if not_supersite_junior? && @user.instructor?
        { live_chat_enabled: true, partner_chat_enabled: true }
      elsif not_supersite_junior? && @user.student?
        {
          live_chat_enabled: live_chat_enabled?,
          partner_chat_enabled: partner_chat_enabled?
        }
      else
        { live_chat_enabled: false, partner_chat_enabled: false }
      end.to_json
    end

    private def not_supersite_junior?
      @program.nil? || !@program.supersite_junior?
    end

    private def valid_section?
      @section && @section.non_zero?
    end
  end
end
