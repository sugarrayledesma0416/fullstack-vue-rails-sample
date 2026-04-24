require 'support/activity_test/activity_data/activity_with_questions'

module ActivityTest
  module ActivityData
    class TableInlineOpenEnded < ActivityWithQuestions
      attr_accessor :input_type
      private def generate_question(question)
        Question.new(
          question_number: question.question_number,
          rank: question.rank,
          wols: question.wols
        )
      end

      class Question
        attr_accessor :question_number, :rank, :wols

        def initialize(question_number:, rank:, wols:)
          self.question_number = question_number
          self.rank = rank
          self.wols = wols
        end
      end

      class WriteOnLine
        attr_accessor :item, :points_possible, :rank, :ref, :sample_answers

        def initialize(points_possible:, rank:, ref: '1', sample_answers: [])
          self.points_possible = points_possible
          self.rank = rank
          self.ref = ref
          self.sample_answers = sample_answers
        end
      end
    end
  end
end
