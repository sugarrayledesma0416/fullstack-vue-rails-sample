require 'support/activity_test/activity_data/base_activity'

module ActivityTest
  module ActivityData
    class ActivityWithQuestions < BaseActivity
      include PromptParser
      attr_accessor :max_attempts, :questions, :references

      def initialize(activity, media_items)
        super(activity, media_items)
        self.max_attempts = activity.max_attempts
        self.questions = activity.questions.map do |question|
          generate_question(question)
        end
        self.references = activity.respond_to?(:references) ? activity.references : []
      end

      def question(number)
        questions[number - 1]
      end
    end
  end
end
