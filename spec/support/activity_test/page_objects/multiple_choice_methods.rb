require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    def from_multiple_choice_question(rank)
      question = @page_object.multiple_choice_question(rank)
      if block_given?
        yield question
      else
        question
      end
    end

    module MultipleChoiceMethods
      def multiple_choice_question(rank)
        MultipleChoiceQuestionElement.new(self, rank)
      end

      # Private methods goes below
      class MultipleChoiceQuestionElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :rank, :page_object

        def initialize(page_object, rank)
          @page_object = page_object
          @rank = rank
        end

        def to_s
          "multiple_choice_question(#{rank})"
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
          MultipleChoiceQuestionChoiceElement.new(page_object, rank, choice_number)
        end

        def choices
          page_object.activity_data.question(rank).choices.map do |choice|
            MultipleChoiceQuestionChoiceElement.new(page_object, rank, choice.number)
          end
        end

        def select_choice(choice_number)
          choice(choice_number).select
        end

        def help_request(request_number)
          MultipleChoiceQuestionHelpRequest.new(page_object, rank, request_number, :help_request)
        end

        def review_request(request_number)
          MultipleChoiceQuestionHelpRequest.new(page_object, rank, request_number, :review_request)
        end

        private def helpable_element(is_overlay = false)
          selector = is_overlay ? format('#overlay-question_%02d_whole_question', rank) : format('#question_%02d_whole_question', rank)
          page_object.find_or_fail(selector, self)
        end

        private def show_hide_help_requests_disclosure
          selector = format('#activity_shell ol.answers li[data-test-rank="%d"] .test-help-request-disclosure', rank)
          page_object.find_or_fail(selector, "#{self}.help_request_disclosure")
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

      class MultipleChoiceQuestionHelpRequest
        include ActivityTest::PageObjects::HelpRequestElementMethods
        attr_reader :request_number, :question_rank, :page_object, :request_type

        def initialize(page_object, question_rank, request_number, request_type)
          @request_number = request_number
          @page_object = page_object
          @question_rank = question_rank
          @request_type = request_type
        end

        def to_s
          if request_type == :help_request
            "multiple_choice_question(#{question_rank}).help_request(#{request_number})"
          else
            "multiple_choice_question(#{question_rank}).review_request(#{request_number})"
          end
        end

        private def help_request_container
          page_object.find_nth_or_fail(container_selector, request_number - 1, self)
        end

        private def container_selector
          if request_type == :help_request
            format('#activity_shell ol.answers li[data-test-rank="%d"] .test-help-request-container.request_help',
                   question_rank)
          else
            format('#activity_shell ol.answers li[data-test-rank="%d"] .test-help-request-container.request_review',
                   question_rank)
          end
        end
      end

      class MultipleChoiceQuestionChoiceElement
        attr_reader :question_rank, :choice_number, :page_object

        def initialize(page_object, question_rank, choice_number)
          @page_object = page_object
          @question_rank = question_rank
          @choice_number = choice_number
        end

        def to_s
          "multiple_choice_question(#{question_rank}).choice(#{choice_number})"
        end

        def mark
          page_object.mark_to_symbol(page_object.find_or_fail(mark_selector, self)[:class])
        end

        def selected?
          page_object.find_or_fail(radio_button_selector, self).checked?
        end

        def select
          radio_button = page_object.find_or_fail(radio_button_selector, self)
          page_object.scroll_to(radio_button)
          # Click on the radio button until it is selected.
          Waiter.new.wait do
            radio_button.click
            selected?
          end
        end

        def editable?
          page_object.has_selector?(radio_button_selector)
        end

        def uneditable?
          page_object.has_no_selector?(radio_button_selector)
        end

        def prompt_text
          page_object.find_or_fail(prompt_text_selector, self).text
        end

        def prompt_image(image_number)
          page_object.find_nth_or_fail(prompt_image_selector, image_number - 1, self)
        end

        private def radio_button_selector
          case page_object.view
          when :preview, :decide, :submit, :retry, :accept, :complete
            format('input[type="radio"]#question_%02d_choice_%02d', question_rank, choice_number)
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end

        private def prompt_text_selector
          case page_object.view
          when :preview, :decide
            format('#question_%02d_choice_%02d_answer_blank label', question_rank, choice_number)
          when :retry
            format('#question_%02d_choice_%02d_answer_blank > :not(input)', question_rank, choice_number)
          when :submit
            format('#question_%02d_choice_%02d > span', question_rank, choice_number)
          when :accept
            format('ul.answer_choices > li#question_%02d_choice_%02d > div > span', question_rank, choice_number)
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
