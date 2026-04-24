module Cartridge
  class BasicOutcomeServiceGradePassbackStrategy < GradePassbackStrategy
    def post_grade
      return unless valid?
      return unless lti_tool_provider.outcome_service?

      response = lti_tool_provider.post_replace_result!(result_grade)
      unless response.success?
        VHLMonitor.error(
          GRADE_PASSBACK_FAILED_MSG,
          lti_params: lti_params,
          response_code: response.response_code,
          response_body: response.post_response.body
        )
      end
    rescue StandardError => e
      VHLMonitor.error(
        GRADE_PASSBACK_FAILED_MSG,
        lti_params: lti_params,
        exception_message: e.message
      )
    end

    private def validate
      report_error('consumer_guid is blank') if consumer_guid.blank?
    end

    private def lis_result_sourcedid
      ScoreDestination.find_by_user_section_activity(
        user: student,
        section: attempt.section_id,
        activity: attempt.activity_id
      )&.lis_result_sourcedid
    end

    private def lis_outcome_service_url
      Cartridge::CourseContextDetail.find_by(
        section_id: attempt.section_id
      )&.lis_outcome_service_url
    end

    private def lti_tool_provider
      return @lti_tool_provider if defined? @lti_tool_provider

      @lti_tool_provider = IMS::LTI::ToolProvider.new(
        cartridge_consumer.key,
        cartridge_consumer.secret,
        'user_id' => student.id,
        'lis_result_sourcedid' => lis_result_sourcedid,
        'lis_outcome_service_url' => lis_outcome_service_url
      )
    end

    private def lti_params
      @lti_params ||= {
        activity_id: attempt.activity_id,
        resource_link_id: resource_link_id,
        user_id: student.id,
        lis_result_sourcedid: lis_result_sourcedid,
        lis_outcome_service_url: lis_outcome_service_url
      }
    end

    private def consumer_guid
      params[:consumer_guid]
    end

    private def cartridge_consumer
      Cartridge::Consumer.find_by!(guid: consumer_guid)
    end

    private def result_grade
      if attempt.has_submittable_activity?
        # We use the score from the gradebook because it takes feedback
        # item into account while attempt.results.score does not.
        score_action = GradebookEngine::GradebookAPI.find_score(
          activity_id: attempt.activity_id,
          section_id: attempt.section_id,
          user_id: attempt.user_id
        )
        score_action.points_earned / score_action.points_possible
      else
        1.0
      end
    end
  end
end
