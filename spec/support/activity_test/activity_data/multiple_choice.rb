require 'support/activity_test/activity_data/activity_with_questions'

module ActivityTest
  module ActivityData
    class MultipleChoice < ActivityWithQuestions
      private def generate_question(question)
        choices = question.choices.map.with_index(1) do |choice, choice_number|
          Choice.new(
            number: choice_number,
            prompt: parse_prompt(choice.to_html),
            is_correct: choice.is_correct
          )
        end
        Question.new(
          question_number: question.question_number,
          rank: question.rank,
          prompt: parse_prompt(question.prompt),
          choices: choices
        )
      end

      class Choice
        attr_accessor :is_correct, :number, :prompt, :image

        def initialize(params = {})
          @number = params[:number]
          @prompt = params[:prompt]
          @is_correct = params[:is_correct]
          @image = params[:image]
        end

        def correct?
          is_correct
        end
      end

      class Question
        attr_accessor :choices, :prompt, :question_number, :rank, :selected_choice

        def initialize(params = {})
          @question_number = params[:question_number]
          @prompt = params[:prompt]
          @choices = params[:choices]
          @rank = params[:rank]
          @selected_choice = nil
        end

        def choice(number)
          choices[number - 1]
        end

        def correct_choice
          choices.find_index(&:is_correct) + 1
        end

        def incorrect_choices
          (1..choices.size).to_a - [correct_choice]
        end
      end
    end
  end
end
