module Cartridge
  class AssignmentAndGradeServiceGradePassbackStrategy < GradePassbackStrategy
    def post_grade
      return unless valid?
      return if line_item_url.blank?

      line_item.sync
      line_item.post_grade(cartridge_user_link.external_user_id, grade)
    rescue GradebookEngine::Lti::AuthTokenError, GradebookEngine::Lti::UnrecoverableSyncError
      # Silently ignore these errors.
    ensure
      if error_collector.has_errors? || error_collector.has_warnings?
        log_errors(error_collector.errors.merge(error_collector.warnings))
      end
    end

    def error_collector
      @error_collector ||= GradebookEngine::Lti::ErrorCollector.new
    end

    private def validate
      report_error('platform_guid is blank') if platform_guid.blank?
    end

    private def platform_guid
      params[:platform_guid]
    end

    private def platform
      @platform ||= GradebookEngine::Lti::Platform.find_by(guid: platform_guid)
    end

    private def cartridge_user_link
      line_item_destination.user.cartridge_user_link
    end

    private def line_item_destination
      return @line_item_destination if defined? @line_item_destination

      @line_item_destination = Cartridge::LineItemDestination.find_by(
        user: attempt.user_id,
        section: attempt.section_id,
        activity: attempt.activity_id
      )
    end

    private def line_item_url
      line_item_destination&.line_item_url
    end

    private def auth_token
      @auth_token ||= GradebookEngine::Lti::AuthToken.new(platform:)
    end

    private def context_link
      @context_link ||= GradebookEngine::Lti::ContextLink.new(
        lti_platform: platform,
        context_id: lms_context_id,
        section:,
        guid: context_link_guid,
        context_title:,
        context_label:
      )
    end

    private def lms_context_id
      cartridge_course_context_detail.lms_context_id
    end

    private def section
      return @section if defined? @section

      @section = line_item_destination.section
    end

    private def context_link_guid
      "common_cartridge_context_details_id: #{cartridge_course_context_detail.id}"
    end

    private def context_title
      section.course.name
    end

    private def context_label
      section.name
    end

    private def cartridge_course_context_detail
      return @cartridge_course_context_detail if defined? @cartridge_course_context_detail

      @cartridge_course_context_detail =
        section.cartridge_course_context_detail
    end

    private def line_item
      @line_item ||= GradebookEngine::Lti::LineItem.new(
        auth_token:,
        context_link:,
        error_collector:,
        existing_line_item:,
        label: nil,
        resource_id: nil,
        score_max: points_possible
      )
    end

    private def existing_line_item
      { 'id' => line_item_url }
    end

    private def score_action
      @score_action ||= GradebookEngine::GradebookAPI.find_score(
        activity_id: attempt.activity_id,
        section_id: attempt.section_id,
        user_id: attempt.user_id
      )
    end

    private def points_earned
      if attempt.has_submittable_activity?
        score_action.points_earned
      else
        1.0
      end
    end

    private def points_possible
      if attempt.has_submittable_activity?
        score_action.points_possible
      else
        1.0
      end
    end

    private def assign_pending_count
      score_action.pending ? 1 : 0
    end

    private def submitted_at
      score_action.submitted_at if attempt.has_submittable_activity?
    end

    private def grade
      DummyGrade.new(
        submitted_at:,
        points_earned_for_display: points_earned,
        points_possible_for_display: points_possible,
        score: points_earned / points_possible,
        pending_count: assign_pending_count
      )
    end

    DummyGrade = Struct.new(
      :submitted_at,
      :points_earned_for_display,
      :points_possible_for_display,
      :score,
      :pending_count,
      keyword_init: true
    ) do
      def level
        'activity'
      end
    end
  end
end
