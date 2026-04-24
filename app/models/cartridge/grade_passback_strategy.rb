module Cartridge
  class GradePassbackStrategy
    GRADE_PASSBACK_FAILED_MSG = 'Failed to send grade back'.freeze

    attr_accessor :attempt, :errors, :params, :student

    def initialize(student, attempt, params)
      self.student = student
      self.attempt = attempt
      self.params = params
      self.errors = []
    end

    def post_grade
      raise NotimplementedError, 'Child classes must define post_grade'
    end

    private def validate
      raise NotimplementedError, 'Child classes must define validate'
    end

    private def valid?
      validate

      log_errors(errors) if errors.present?

      errors.blank?
    end

    private def log_errors(errors)
      VHLMonitor.error(
        GRADE_PASSBACK_FAILED_MSG,
        activity_id: attempt.activity_id,
        errors:,
        params:,
        resource_link_id:,
        user_id: student.id
      )
    end

    private def resource_link_id
      Cartridge::ResourceLink.find_by(
        resource_id: attempt.activity_id,
        resource_type: :activity
      )&.resource_link_id
    end

    private def report_error(message)
      errors << message
      false
    end
  end
end
