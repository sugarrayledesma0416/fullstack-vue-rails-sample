module AI
  module OverallCommentGenerators
    class ActivityGenerator
      attr_reader :attempt, :grading_suggestion_input

      def initialize(attempt:, grading_suggestion_input:)
        @attempt = attempt
        @grading_suggestion_input = grading_suggestion_input
      end

      def generate
        return unless feature_enabled?

        if activity.includes_activity_type?('open_ended')
          AI::OverallCommentGenerators::OpenEndedActivityGeneratorWorker.perform_async(
            attempt.id,
            prompt.id,
            grading_suggestion_input&.id
          )
        end
        if activity.includes_activity_type?('composition')
          AI::OverallCommentGenerators::CompositionActivityGeneratorWorker.perform_async(
            attempt.id,
            prompt.id,
            grading_suggestion_input&.id
          )
        end
      end

      private def feature_enabled?
        section&.program&.ai_grading_feature_enabled? ||
        section&.instructor&.can_use_ai_grading_suggestions?
      end

      private def activity
        attempt.activity
      end

      private def prompt
        @prompt ||= AI::OverallCommentPrompt.current
      end

      private def section
        @section ||= attempt.section
      end
    end
  end
end
