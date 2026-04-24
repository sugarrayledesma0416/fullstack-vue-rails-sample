require 'support/activity_test/activity_data/activity_with_questions'

module ActivityTest
  module ActivityData
    class FillInTheBlanks < ActivityWithQuestions
      private def generate_question(question)
        Question.new(
          question_number: question.question_number,
          rank: question.rank,
          prompt: parse_prompt(question.prompt.node),
          wol_count: question.wols.size
        )
      end

      class MenuOption
        attr_accessor :number
        attr_accessor :text
        attr_accessor :is_correct

        def initialize(number:, text:, is_correct:)
          @number = number
          @text = text
          @is_correct = is_correct
        end

        def correct?
          is_correct
        end
      end

      class Question
        attr_accessor :question_number, :rank
        attr_accessor :prompt
        attr_accessor :wol_count

        def initialize(prompt:, question_number:, rank:, wol_count:)
          @question_number = question_number
          @rank = rank
          @prompt = prompt
          @wol_count = wol_count
        end
      end
    end
  end
end
