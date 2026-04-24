require 'ims/lti'

module Cartridge
  class GradePassback
    attr_accessor :attempt, :params, :student

    def initialize(student, attempt, params)
      self.student = student
      self.attempt = attempt
      self.params = params || {}
    end

    def process
      return unless valid?

      grade_passback_strategy.post_grade
    end

    private def valid?
      return true if legacy_lti_version? || latest_lti_version?

      report_error('LTI version is not supported')
    end

    private def report_error(message)
      VHLMonitor.error(
        'Failed to send grade back',
        activity_id: attempt.activity_id,
        errors: [message],
        params: params,
        user_id: student.id
      )
      false
    end

    private def grade_passback_strategy
      @grade_passback_strategy ||= if legacy_lti_version?
                                     basic_outcome_service_grade_passback_strategy
                                   elsif latest_lti_version?
                                     assignment_and_grade_service_grade_passback_strategy
                                   end
    end

    private def basic_outcome_service_grade_passback_strategy
      BasicOutcomeServiceGradePassbackStrategy.new(
        student,
        attempt,
        params.slice(:consumer_guid)
      )
    end

    private def assignment_and_grade_service_grade_passback_strategy
      AssignmentAndGradeServiceGradePassbackStrategy.new(
        student,
        attempt,
        params.slice(:platform_guid)
      )
    end

    # If a student did a cartridge launch before the code deploy, the lti_version
    # will not be present in the session. So if it's balnk, we assume it's a
    # legacy launch.
    private def legacy_lti_version?
      lti_version == Cartridge::LaunchesController::LEGACY_LTI_VERSION ||
      lti_version.blank?
    end

    private def latest_lti_version?
      lti_version == Cartridge::LaunchesController::LATEST_LTI_VERSION
    end

    private def lti_version
      params[:lti_version]
    end
  end
end
