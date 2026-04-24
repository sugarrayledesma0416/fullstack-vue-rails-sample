require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    def from_table_inline_open_ended_question(q_rank, wol_rank)
      question = @page_object.table_inline_open_ended_question(q_rank, wol_rank)
      if block_given?
        yield question
      else
        question
      end
    end

    module TableInlineOpenEndedMethods
      def table_inline_open_ended_question(q_rank, wol_rank)
        TableInlineOpenEndedQuestionElement.new(self, q_rank, wol_rank)
      end

      # Private methods goes below
      class TableInlineOpenEndedQuestionElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :q_rank, :wol_rank, :page_object

        def initialize(page_object, q_rank, wol_rank)
          @page_object = page_object
          @q_rank = q_rank
          @wol_rank = wol_rank
        end

        def to_s
          "table_inline_open_ended_question(#{q_rank}, #{wol_rank})"
        end

        def mark
          selector = format('ol.answers li[data-test-rank="%d"]', q_rank)
          page_object.mark_to_symbol(page_object.find_or_fail(selector, self)[:class])
        end

        def whole_question
          selector = format('#question_%02d_whole_question', q_rank)
          page_object.find_or_fail(selector, self)
        end

        def prompt_text
          selector = format('#question_%02d .c-table-wrapper .c-table', q_rank)
          page_object.find_or_fail(selector, self).text
        end

        def answer
          TableInlineOpenEndedQuestionAnswerElement.new(page_object, q_rank, wol_rank)
        end

        def choose_answer(s)
          TableInlineOpenEndedQuestionAnswerElement.new(page_object, q_rank, wol_rank).set_text(s)
        end

        def sample_answers
          TableInlineOpenEndedQuestionSampleAnswersElement.new(page_object, q_rank, wol_rank)
        end

        def help_request(request_number)
          TableInlineOpenEndedQuestionWholeQuestionHelpRequest.new(
            page_object, q_rank, request_number
          )
        end

        private def helpable_element(is_overlay = false)
          selector = if is_overlay
                       format('#overlay-question_%02d_whole_question', q_rank)
                     else
                       format('#question_%02d_whole_question', q_rank)
                     end
          page_object.find_or_fail(selector, self)
        end

        private def show_hide_help_requests_disclosure
          selector = format(
            '#activity_shell ol.answers li[data-test-rank="%d"] .test-help-request-disclosure',
            q_rank
          )
          page_object.find_or_fail(selector, "#{self}.help_request_disclosure")
        end
      end

      class TableInlineOpenEndedQuestionWholeQuestionHelpRequest
        include ActivityTest::PageObjects::HelpRequestElementMethods
        attr_reader :request_number, :question_rank, :page_object

        def initialize(page_object, question_rank, request_number)
          @request_number = request_number
          @page_object = page_object
          @question_rank = question_rank
        end

        def to_s
          "table_inline_open_ended_question(#{question_rank}).help_request(#{request_number})"
        end

        private def help_request_container
          selector = format(
            '#activity_shell ol.answers li[data-test-rank="%d"] .test-help-request-container',
            question_rank
          )
          page_object.find_nth_or_fail(selector, request_number - 1, self)
        end
      end

      class TableInlineOpenEndedQuestionAnswerElement
        include ActivityTest::PageObjects::HelpableItemElementMethods

        attr_reader :question_rank, :wol_rank, :page_object

        def initialize(page_object, question_rank, wol_rank)
          @page_object = page_object
          @question_rank = question_rank
          @wol_rank = wol_rank
          activity_data = page_object.activity_data
          @input_type = defined?(activity_data.input_type) ? activity_data.input_type : 'input'
        end

        def to_s
          "table_inline_open_ended_question(#{question_rank}, #{wol_rank}).answer"
        end

        def text
          case page_object.view
          when :preview, :decide, :retry, :submit
            selector = format(@input_type + '#question_%02d_wol_%1d', question_rank, wol_rank)
            page_object.find_or_fail(selector, self).value
          when :accept, :complete
            selector = format('#question_%02d_wol_%1d_student_response', question_rank, wol_rank)
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
            selector = format(@input_type + '#question_%02d_wol_%1d', question_rank, wol_rank)
            page_object.find_or_fail(selector, self).set(s)
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end

        def help_request(help_request_number)
          TableInlineOpenEndedQuestionAnswerHelpRequest.new(
            page_object, question_rank, help_request_number, :help_request
          )
        end

        def review_request(review_request_number)
          TableInlineOpenEndedQuestionAnswerHelpRequest.new(
            page_object, question_rank, review_request_number, :review_request
          )
        end

        private def helpable_element(is_overlay = false)
          select_prefix = (is_overlay ? 'overlay-' : '')
          selector = case page_object.view
                     when :accept, :complete
                       format("##{select_prefix}question_%02d_wol_%1d", question_rank, wol_rank)
                     when :preview, :decide, :retry, :submit
                       format("##{select_prefix}question_%02d_whole_question", question_rank)
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

      class TableInlineOpenEndedQuestionAnswerHelpRequest
        include ActivityTest::PageObjects::HelpRequestElementMethods

        attr_reader :request_number, :question_rank, :page_object, :request_type

        def initialize(page_object, question_rank, request_number, request_type)
          @request_number = request_number
          @page_object = page_object
          @question_rank = question_rank
          @request_type = request_type
        end

        def to_s
          base = "table_inline_open_ended_question(#{question_rank}).answer"
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

      class TableInlineOpenEndedQuestionSampleAnswersElement
        attr_reader :question_rank, :page_object, :wol_rank

        def initialize(page_object, question_rank, wol_rank)
          @page_object = page_object
          @question_rank = question_rank
          @wol_rank = wol_rank
        end

        def to_s
          "table_inline_open_ended_question(#{question_rank}, #{wol_rank}).sample_answers"
        end

        def show
          selector = format(
            '#question_%02d_wol_%1d_instructor_feedback .sample_answer_toggle',
            question_rank,
            wol_rank
          )
          element = page_object.find_or_fail(selector, self)
          element.click if element.text =~ /View sample answer/
        end

        def hide
          selector = format(
            '#question_%02d_instructor_feedback .sample_answer_toggle',
            question_rank
          )
          element = page_object.find_or_fail(selector, self)
          element.click if element.text =~ /View sample answer/
        end

        def answer(number)
          TableInlineOpenEndedQuestionSampleAnswerElement.new(
            page_object, question_rank, wol_rank, number
          )
        end
      end

      class TableInlineOpenEndedQuestionSampleAnswerElement
        attr_reader :answer_number, :question_rank, :page_object, :wol_rank

        def initialize(page_object, question_rank, wol_rank, answer_number)
          @page_object = page_object
          @question_rank = question_rank
          @wol_rank = wol_rank
          @answer_number = answer_number
        end

        def to_s
          "table_inline_open_ended_question(#{question_rank}).sample_answer(#{answer_number})"
        end

        def text
          selector = format(
            '#question_%02d_wol_%1d_instructor_feedback .sample_answer_container div.sample_answer',
            question_rank,
            wol_rank
          )
          page_object.find_nth_or_fail(selector, answer_number - 1, self).text
        end
      end
    end
  end
end
