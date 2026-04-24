require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    def from_multiple_answer_question(rank)
      question = @page_object.multiple_answer_question(rank)
      if block_given?
        yield question
      else
        question
      end
    end

    module MultipleAnswerMethods
      def multiple_answer_question(rank)
        MultipleAnswerQuestionElement.new(self, rank)
      end

      # Private methods goes below
      class MultipleAnswerQuestionElement
        # include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :rank, :page_object

        def initialize(page_object, rank)
          @page_object = page_object
          @rank = rank
        end

        def to_s
          "multiple_answer_question(#{rank})"
        end

        def mark
          page_object.mark_to_symbol(page_object.find_or_fail(mark_selector, self)[:class])
        end

        def prompt_text
          selector = format('#question_%02d_prompt', rank)
          page_object.find_or_fail(selector, self).text
        end

        def prompt_image(image_number)
          selector = format('#question_%02d_prompt img', rank)
          page_object.find_nth_or_fail(selector, image_number - 1, self)
        end

        def choice(choice_number)
          MultipleAnswerQuestionChoiceElement.new(page_object, rank, choice_number)
        end

        def choices
          page_object.activity_data.question(rank).choices.map do |choice|
            MultipleAnswerQuestionChoiceElement.new(page_object, rank, choice.number)
          end
        end

        def select_choices(choice_numbers)
          choice_numbers.each do |choice_number|
            choice(choice_number).select
          end
        end

        def has_checked_only?(choice_numbers)
          choices.all? do |choice|
            if choice_numbers.include?(choice.choice_number)
              choice.checked?
            else
              !choice.checked?
            end
          end
        end

        private def mark_selector
          case page_object.view
          when :preview
            format('#activity_shell ol.answers li[data-test-rank="%d"] fieldset', rank)
          else
            format('#activity_shell ol.answers li[data-test-rank="%d"]', rank)
          end
        end
      end

      class MultipleAnswerQuestionChoiceElement
        include RspecJsCommonHelpers

        attr_reader :question_rank, :choice_number, :page_object

        def initialize(page_object, question_rank, choice_number)
          @page_object = page_object
          @question_rank = question_rank
          @choice_number = choice_number
        end

        def to_s
          "multiple_answer_question(#{question_rank}).choice(#{choice_number})"
        end

        def mark
          page_object.mark_to_symbol(page_object.find_or_fail(mark_selector, self)[:class])
        end

        def checked?
          page_object.find_or_fail(checkbox_selector, self).checked?
        end

        def select
          checkbox = page_object.find_or_fail(checkbox_selector, self)
          page_object.scroll_to(checkbox)
          # Click on the checkbox until it is checked.
          Waiter.new.wait do
            page_object.find("label[for=#{checkbox[:id]}]").click
            checked?
          end
        end

        def editable?
          page_object.has_selector?(checkbox_selector)
        end

        def uneditable?
          page_object.has_no_selector?(checkbox_selector)
        end

        def prompt_text
          page_object.find_or_fail(prompt_text_selector, self).text
        end

        def prompt_image(image_number)
          page_object.find_nth_or_fail(prompt_image_selector, image_number - 1, self)
        end

        private def checkbox_selector
          case page_object.view
          when :preview, :decide, :submit, :retry, :accept, :complete
            format('input[type="checkbox"]#question_%02d_choice_%02d', question_rank, choice_number)
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end

        private def prompt_text_selector
          format(prompt_text_template, question_rank, choice_number)
        end

        private def prompt_text_template
          case page_object.view
          when :preview, :decide
            '#question_%02d_choice_%02d_answer_blank label'
          when :retry
            '#question_%02d_choice_%02d_answer_blank > :not(input)'
          when :submit then
            '#question_%02d_choice_%02d > span'
          when :accept
            'ul.answer_choices > li#question_%02d_choice_%02d >span'
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end

        private def prompt_image_selector
          case page_object.view
          when :preview, :decide, :retry
            format('#question_%02d_choice_%02d_answer_blank img', question_rank, choice_number)
          when :submit
            format('#question_%02d_choice_%02d img', question_rank, choice_number)
          when :accept
            format('ul.answer_choices > li#question_%02d_choice_%02d span img', question_rank, choice_number)
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end

        private def mark_selector
          case page_object.view
          when :preview, :decide, :retry
            format('#question_%02d_choice_%02d_answer_blank', question_rank, choice_number)
          when :submit
            format('#question_%02d_choice_%02d', question_rank, choice_number)
          when :accept
            format('ul.answer_choices > li#question_%02d_choice_%02d', question_rank, choice_number)
          when :complete
            format('ul.answer_choices > li#question_%02d_choice_%02d', question_rank, choice_number)
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end
      end
    end
  end
end
