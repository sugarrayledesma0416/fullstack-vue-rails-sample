module GradebookEngineTest
  module PageObjects
    class InstructorFeedbackPageObject
      include Capybara::DSL
      include CapybaraViewHelpers

      attr_accessor :question

      def initialize(question)
        self.question = question
      end

      def to_s
        "instructor_feedback_for_#{question.label}"
      end

      def comment
        container.find('.test-comment-text').text
      end

      def score
        container.find('.test-score-text').text
      end

      def has_audio_player?
        container.has_selector?('.test-recording-playback-button')
      end

      def has_no_audio_player?
        container.has_no_selector?('.test-recording-playback-button')
      end

      private def container
        find_or_fail("##{question.label}_instructor_feedback_container", self)
      end
    end

    def for_instructor_feedback(question)
      yield InstructorFeedbackPageObject.new(question)
    end
  end
end
