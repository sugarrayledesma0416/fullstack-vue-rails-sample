require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    def from_open_ended_question(rank)
      question = @page_object.open_ended_question(rank)
      if block_given?
        yield question
      else
        question
      end
    end

    module OpenEndedMethods
      def open_ended_question(rank)
        OpenEndedQuestionElement.new(self, rank)
      end

      # Private methods goes below
      class OpenEndedQuestionElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :rank, :page_object

        def initialize(page_object, rank)
          @page_object = page_object
          @rank = rank
        end

        def to_s
          "open_ended_question(#{rank})"
        end

        def mark
          selector = format('ol.answers li[data-test-rank="%d"]', rank)
          page_object.mark_to_symbol(page_object.find_or_fail(selector, self)[:class])
        end

        def prompt_text
          selector = format('#question_%02d_prompt', rank)
          page_object.find_or_fail(selector, self).text
        end

        def prompt_image(image_number)
          selector = format('#question_%02d_prompt img', rank)
          page_object.find_nth_or_fail(selector, image_number - 1, self)
        end

        def answer
          OpenEndedQuestionAnswerElement.new(page_object, rank)
        end

        def choose_answer(s)
          OpenEndedQuestionAnswerElement.new(page_object, rank).set_text(s)
        end

        def sample_answers
          OpenEndedQuestionSampleAnswersElement.new(page_object, rank)
        end

        def help_request(request_number)
          OpenEndedQuestionPromptHelpRequest.new(page_object, rank, request_number)
        end

        private def helpable_element(is_overlay = false)
          selector = is_overlay ? format('#overlay-question_%02d_prompt', rank) : format('#question_%02d_prompt', rank)
          page_object.find_or_fail(selector, self)
        end

        private def show_hide_help_requests_disclosure
          selector = format(
            '#activity_shell ol.answers li[data-test-rank="%d"] .test-help-request-disclosure',
            rank
          )
          page_object.find_or_fail(selector, "#{self}.help_request_disclosure")
        end
      end

      class OpenEndedQuestionPromptHelpRequest
        include ActivityTest::PageObjects::HelpRequestElementMethods
        attr_reader :request_number, :question_rank, :page_object

        def initialize(page_object, question_rank, request_number)
          @request_number = request_number
          @page_object = page_object
          @question_rank = question_rank
        end

        def to_s
          "open_ended_question(#{question_rank}).help_request(#{request_number})"
        end

        private def help_request_container
          selector = format(
            '#activity_shell ol.answers li[data-test-rank="%d"] .test-help-request-container',
            question_rank
          )
          page_object.find_nth_or_fail(selector, request_number - 1, self)
        end
      end

      class OpenEndedQuestionAnswerElement
        include ActivityTest::PageObjects::HelpableItemElementMethods

        attr_reader :question_rank, :page_object

        def initialize(page_object, question_rank)
          @page_object = page_object
          @question_rank = question_rank
          activity_data = page_object.activity_data
          @input_type = defined?(activity_data.input_type) ? activity_data.input_type : 'textarea'
        end

        def to_s
          "open_ended_question(#{question_rank}).answer"
        end

        def text
          case page_object.view
          when :preview, :decide, :retry
            selector = format(@input_type + '#question_%02d', question_rank)
            page_object.find_or_fail(selector, self).value
          when :submit
            selector = format('#question_%02d_whole_question .openended_readonly', question_rank)
            page_object.find_or_fail(selector, self).text
          when :accept, :complete
            selector = format('#question_%02d_student_response', question_rank)
            # The :all param will permit finding the text regardless of the open/closed
            # state of the disclosure.
            page_object.find_or_fail(selector, self).text(:all)
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end

        def set_text(s)
          case page_object.view
          when :preview, :decide, :retry
            selector = format(@input_type + '#question_%02d', question_rank)
            page_object.find_or_fail(selector, self).set(s)
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end

        def help_request(help_request_number)
          OpenEndedQuestionAnswerHelpRequest.new(
            page_object, question_rank, help_request_number, :help_request
          )
        end

        def review_request(review_request_number)
          OpenEndedQuestionAnswerHelpRequest.new(
            page_object, question_rank, review_request_number, :review_request
          )
        end

        private def helpable_element(is_overlay = false)
          selector = if is_overlay
                       format('#overlay-question_%02d', question_rank)
                     else
                       format('#question_%02d', question_rank)
                     end
          page_object.find_or_fail(selector, self)
        end

        private def show_hide_help_requests_disclosure
          selector = format(
            '#question_%02d_whole_question .test-help-request-disclosure',
            question_rank
          )
          page_object.find_or_fail(selector, "#{self}.toggle_help_request")
        end
      end

      class OpenEndedQuestionAnswerHelpRequest
        include ActivityTest::PageObjects::HelpRequestElementMethods

        attr_reader :request_number, :question_rank, :page_object, :request_type

        def initialize(page_object, question_rank, request_number, request_type)
          @request_number = request_number
          @page_object = page_object
          @question_rank = question_rank
          @request_type = request_type
        end

        def to_s
          base = "open_ended_question(#{question_rank}).answer"
          if request_type == :help_request
            "#{base}.help_request(#{request_number})"
          else
            "#{base}.review_request(#{request_number})"
          end
        end

        private def help_request_container
          selector = format(
            '#question_%02d_whole_question .test-help-request-container',
            question_rank
          )
          page_object.find_nth_or_fail(selector, request_number - 1, self)
        end
      end

      class OpenEndedQuestionSampleAnswersElement
        attr_reader :question_rank, :page_object

        def initialize(page_object, question_rank)
          @page_object = page_object
          @question_rank = question_rank
        end

        def to_s
          "open_ended_question(#{question_rank}).sample_answers"
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
          OpenEndedQuestionSampleAnswerElement.new(page_object, question_rank, number)
        end
      end

      class OpenEndedQuestionSampleAnswerElement
        attr_reader :answer_number, :question_rank, :page_object

        def initialize(page_object, question_rank, answer_number)
          @page_object = page_object
          @question_rank = question_rank
          @answer_number = answer_number
        end

        def to_s
          "open_ended_question(#{question_rank}).sample_answer(#{answer_number})"
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
