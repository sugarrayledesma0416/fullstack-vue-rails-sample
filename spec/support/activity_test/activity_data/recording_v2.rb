require 'support/activity_test/activity_data/activity_with_questions'

module ActivityTest
  module ActivityData
    class RecordingV2 < ActivityWithQuestions
      private def generate_question(question)
        Question.new(
          question_number: question.question_number,
          rank: question.rank,
          prompt: parse_prompt(question.prompt),
          sample_answers: question.sample_answer
        )
      end

      private def parse_prompt(prompt)
        Prompt.new(prompt.nil? ? [] : prompt_elements(prompt))
      end

      private def prompt_elements(prompt)
        # We only supports prompt text for now.
        [ActivityTest::ActivityData::PromptText.new(text: prompt.body_content)]
      end

      class Question
        attr_accessor :question_number, :rank
        attr_accessor :prompt
        attr_accessor :sample_answers

        def initialize(question_number:, rank:, prompt:, sample_answers:)
          @question_number = question_number
          @rank = rank
          @prompt = prompt
          @sample_answers = sample_answers
        end
      end
    end
  end
end
