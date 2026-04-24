require 'support/activity_test/activity_data/activity_with_questions'

module ActivityTest
  module ActivityData
    class DropDown < ActivityWithQuestions
      private def generate_question(question)
        Question.new(
          question_number: question.question_number,
          rank: question.rank,
          prompt: parse_prompt(question.prompt.node),
          menus: question.menus.map { |menu| parse_menu(menu) }
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

      class Menu
        attr_accessor :ref
        attr_accessor :options

        def initialize(ref:, options:)
          @ref = ref
          @options = options
        end

        def option(number)
          options[number - 1]
        end

        def correct_option
          options.find(&:is_correct)
        end

        def incorrect_options
          options - [correct_option]
        end
      end

      class Question
        attr_accessor :question_number, :rank
        attr_accessor :prompt
        attr_accessor :menus

        def initialize(question_number:, rank:, prompt:, menus:)
          @question_number = question_number
          @rank = rank
          @prompt = prompt
          @menus = menus
        end

        def menu(ref)
          menus[ref - 1]
        end
      end

      private def parse_menu(menu)
        options = menu.options.map.with_index(1) do |option, option_number|
          MenuOption.new(
            number: option_number,
            text: option.text,
            is_correct: option.is_correct
          )
        end
        Menu.new(
          ref: Integer(menu.ref),
          options: options
        )
      end
    end
  end
end
