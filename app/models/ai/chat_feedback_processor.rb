module AI
  class ChatFeedbackProcessor
    def initialize(params_json:, program:, activity:, instructor:)
      @params_json = params_json
      @program = program
      @activity = activity
      @instructor = instructor
      @errors = []
    end

    attr_reader :errors

    def process!
      begin
        parsed = JSON.parse(@params_json) rescue {}

        Array(parsed['flaggedItems']).each do |item|
          process_item(item)
        end

        additional_feedback = parsed['additionalFeedback']
        session_id = parsed['sessionId']
        process_overall_feedback(additional_feedback, session_id) if additional_feedback.present?
      rescue => e
        VHLMonitor.error(
          "General error during chat feedback processing #{e.message}",
          session_id: session_id,
          params_json: @params_json
        )
      end

      if errors.any?
        Rails.logger.warn("[AI::ChatFeedbackProcessor] Completed with #{errors.size} error(s):")
        errors.each { |err| Rails.logger.warn(err.inspect) }
      end
    end

    private

    def process_item(item)
      message_guid = item['guid']
      return unless message_guid

      rating_category_id = item['reason_id']
      return unless rating_category_id

      chat_message = AI::ConversationSessionMessage.find_by(guid: message_guid)
      return unless chat_message

      feedback = AI::ChatFeedbackFlag.find_or_initialize_by(
        program_id: @program.id,
        activity_id: @activity.id,
        message_guid: message_guid
      )

      feedback.graded_by_id = @instructor.id
      feedback.comment = item['comment']
      feedback.ai_virtual_chat_session_messages_id = chat_message.id
      feedback.ai_suggestion_rating_categories_id = rating_category_id
      feedback.save!
    rescue => e
      @errors << { context: 'process_item', guid: item['guid'], error: e.message }
      log_error("Error in process_item for message #{item['guid']}", e)
    end

    def process_overall_feedback(comment, session_id)
      session = AI::ConversationSession.find_by(id: session_id)
      return unless session

      feedback = AI::ChatOverallFeedback.find_or_initialize_by(
        program_id: @program.id,
        activity_id: @activity.id,
        graded_by_id: @instructor.id
      )

      feedback.comment = comment
      feedback.ai_virtual_chat_sessions_id = session.id
      feedback.save!
    rescue => e
      @errors << { context: 'process_overall_feedback', session_id: session_id, error: e.message }
      log_error("Error in process_overall_feedback", e)
    end

    def log_error(context, exception)
      Rails.logger.error("[AI::ChatFeedbackProcessor] #{context} - #{exception.class}: #{exception.message}")
    end
  end
end
