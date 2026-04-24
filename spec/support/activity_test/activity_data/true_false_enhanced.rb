require 'support/activity_test/activity_data/multiple_choice'

module ActivityTest
  module ActivityData
    class TrueFalseEnhanced < MultipleChoice
      private def generate_question(question)
        choices = question.choices.map.with_index(1) do |choice, choice_number|
          Choice.new(
            number: choice_number,
            prompt: parse_prompt(choice.to_html),
            is_correct: choice.is_correct
          )
        end
        Question.new(
          choices: choices,
          points_possible: question.points_possible,
          prompt: parse_prompt(question.prompt),
          question_number: question.question_number,
          rank: question.rank,
          sample_answers: question.sample_answer
        )
      end

      class Choice
        attr_accessor :is_correct, :number, :prompt

        def initialize(params = {})
          @number = params[:number]
          @prompt = params[:prompt]
          @is_correct = params[:is_correct]
        end

        def correct?
          is_correct
        end
      end

      class Question
        attr_accessor :choices, :points_possible, :prompt, :question_number,
                      :rank, :sample_answers

        def initialize(params = {})
          @question_number = params[:question_number]
          @prompt = params[:prompt]
          @choices = params[:choices]
          @rank = params[:rank]
          @sample_answers = params[:sample_answers]
          @points_possible = params[:points_possible]
        end

        def choice(number)
          choices[number - 1]
        end

        def correct_choice
          choices.find_index(&:is_correct) + 1
        end

        def incorrect_choice
          incorrect_choices.first
        end

        def incorrect_choices
          (1..choices.size).to_a - [correct_choice]
        end
      end
    end
  end
end
