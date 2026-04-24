module AI
  module GradingSuggestionGenerators
    class ActivityGenerator
      attr_reader :attempt, :grading_suggestion_input
      attr_accessor :async

      def initialize(attempt:, grading_suggestion_input:, async: true)
        @attempt = attempt
        @grading_suggestion_input = grading_suggestion_input
        self.async = async
      end

      def generate
        return unless feature_enabled?

        worker_args = [attempt.id, prompt.id, grading_suggestion_input&.id]

        if activity.includes_activity_type?('open_ended')
          worker_class = AI::GradingSuggestionGenerators::OpenEndedActivityGeneratorWorker
          perform(worker_class, worker_args)
        end

        if activity.includes_activity_type?('composition')
          worker_class = AI::GradingSuggestionGenerators::CompositionActivityGeneratorWorker
          perform(worker_class, worker_args)
        end
      end

      private def perform(worker_class, worker_args)
        if async
          worker_class.perform_async(*worker_args)
        else
          worker_class.perform_inline(*worker_args)
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
        @prompt ||= AI::GradingSuggestionPrompt.current
      end

      private def section
        @section ||= attempt.section
      end
    end
  end
end
