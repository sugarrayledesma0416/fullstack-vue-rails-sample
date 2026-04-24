require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    def from_true_false_enhanced_question(rank)
      question = @page_object.true_false_enhanced_question(rank)
      if block_given?
        yield question
      else
        question
      end
    end

    module TrueFalseEnhancedMethods
      def true_false_enhanced_question(rank)
        TrueFalseEnhancedQuestionElement.new(self, rank)
      end

      # Private methods goes below
      class TrueFalseEnhancedQuestionElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :rank, :page_object

        def initialize(page_object, rank)
          @page_object = page_object
          @rank = rank
        end

        def to_s
          "true_false_enhanced_question(#{rank})"
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
          TrueFalseEnhancedQuestionChoiceElement.new(page_object, rank, choice_number)
        end

        def choice_true
          choice(1)
        end

        def choice_false
          choice(2)
        end

        def choices
          page_object.activity_data.question(rank).choices.map do |choice|
            TrueFalseEnhancedQuestionChoiceElement.new(page_object, rank, choice.number)
          end
        end

        def correction
          TrueFalseEnhancedQuestionCorrectionElement.new(page_object, rank)
        end

        def sample_answers
          TrueFalseEnhancedQuestionSampleAnswersElement.new(page_object, rank)
        end

        def help_request(request_number)
          TrueFalseEnhancedQuestionHelpRequest.new(page_object, rank, request_number, :help_request)
        end

        def review_request(request_number)
          TrueFalseEnhancedQuestionHelpRequest.new(page_object, rank, request_number, :review_request)
        end

        private def helpable_element
          selector = format('#question_%02d_whole_question', rank)
          page_object.find_or_fail(selector, self)
        end

        private def mark_selector
          format('#activity_shell ol.answers li[data-test-rank="%d"]', rank)
        end
      end

      class TrueFalseEnhancedQuestionHelpRequest
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
            "true_false_enhanced_question(#{question_rank}).help_request(#{request_number})"
          else
            "true_false_enhanced_question(#{question_rank}).review_request(#{request_number})"
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

      class TrueFalseEnhancedQuestionCorrectionElement
        include ActivityTest::PageObjects::HelpableItemElementMethods

        attr_reader :question_rank, :page_object

        def initialize(page_object, question_rank)
          @page_object = page_object
          @question_rank = question_rank
        end

        def to_s
          "true_false_enhanced_question(#{question_rank}).correction"
        end

        def text=(value)
          correction_element.set(value)
        end

        def text
          case page_object.view
          when :preview, :decide, :retry
            correction_element.value
          when :submit, :complete, :accept
            correction_element.text
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end

        def exist?
          page_object.page.has_selector?(correction_selector, visible: true)
        end

        def not_exist?
          page_object.page.has_no_selector?(correction_selector, visible: true)
        end

        private def correction_element
          page_object.find_or_fail(correction_selector, self)
        end

        def review_request(review_request_number)
          TrueFalseEnhancedQuestionCorrectionReviewRequest.new(
            page_object, question_rank, review_request_number
          )
        end

        private def helpable_element(is_overlay = false)
          selector = if is_overlay
                       format('#overlay-question_%02d_correction', question_rank)
                     else
                       format('#question_%02d_correction', question_rank)
                     end
          page_object.find_or_fail(selector, self)
        end

        private def show_hide_help_requests_disclosure
          selector = "#{correction_selector} .test-help-request-disclosure"
          page_object.find_or_fail(selector, "#{self}.help_request_disclosure")
        end

        private def correction_selector
          case page_object.view
          when :preview, :decide, :retry
            format('textarea[name="question_%02d_correction"]', question_rank)
          when :submit
            format(
              '#question_%02d .answer_choices label[for="question_%02d"]',
              question_rank,
              question_rank
            )
          when :complete, :accept
            format('.test-question_%02d_correction_container', question_rank)
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end
      end

      class TrueFalseEnhancedQuestionCorrectionReviewRequest
        include ActivityTest::PageObjects::HelpRequestElementMethods

        attr_reader :request_number, :question_rank, :page_object

        def initialize(page_object, question_rank, request_number)
          @request_number = request_number
          @page_object = page_object
          @question_rank = question_rank
        end

        def to_s
          "true_false_enhanced_question(#{question_rank}.review_request(#{request_number})"
        end

        private def help_request_container
          selector = format(
            '#question_%02d_whole_question .test-help-request-container',
            question_rank
          )
          page_object.find_nth_or_fail(selector, request_number - 1, self)
        end
      end

      class TrueFalseEnhancedQuestionChoiceElement
        attr_reader :question_rank, :choice_number, :page_object

        def initialize(page_object, question_rank, choice_number)
          @page_object = page_object
          @question_rank = question_rank
          @choice_number = choice_number
        end

        def to_s
          "true_false_enhanced_question(#{question_rank}).choice(#{choice_number})"
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
          when :submit, :accept
            format('#question_%02d_choice_%02d label', question_rank, choice_number)
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

      class TrueFalseEnhancedQuestionSampleAnswersElement
        attr_reader :question_rank, :page_object

        def initialize(page_object, question_rank)
          @page_object = page_object
          @question_rank = question_rank
        end

        def to_s
          "true_false_enhanced_question(#{question_rank}).sample_answers"
        end

        def show
          selector = format('#question_%02d_whole_question .sample_answer_toggle', question_rank)
          element = page_object.find_or_fail(selector, self)
          element.click if element.text =~ /View sample answer/
        end

        def hide
          selector = format('#question_%02d_whole_question .sample_answer_toggle', question_rank)
          element = page_object.find_or_fail(selector, self)
          element.click if element.text =~ /View sample answer/
        end

        def answer(number)
          TrueFalseEnhancedQuestionSampleAnswerElement.new(page_object, question_rank, number)
        end
      end

      class TrueFalseEnhancedQuestionSampleAnswerElement
        attr_reader :answer_number, :question_rank, :page_object

        def initialize(page_object, question_rank, answer_number)
          @page_object = page_object
          @question_rank = question_rank
          @answer_number = answer_number
        end

        def to_s
          "true_false_enhanced_question(#{question_rank}).sample_answer(#{answer_number})"
        end

        def text
          selector = format('#question_%02d_whole_question .sample_answer_container div.sample_answer',
                            question_rank)
          page_object.find_nth_or_fail(selector, answer_number - 1, self).text
        end
      end
    end
  end
end
