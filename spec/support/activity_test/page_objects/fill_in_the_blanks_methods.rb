require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    def from_fib_question(rank)
      question = @page_object.fib_question(rank)
      if block_given?
        yield question
      else
        question
      end
    end

    module FillInTheBlanksMethods
      def fib_question(rank)
        FillInTheBlanksQuestionElement.new(self, rank)
      end

      # Private methods goes below
      def fib_wol_submitted_token_elements(wol)
        case view
        when :submit
          selector = format('#question_%02d_wol_%d > span:not(.u-no-visual)', wol.question_rank, wol.wol_ref)
          page.all(selector)
        when :accept, :complete
          selector = format('#question_%02d_wol_%d .student_answer span:not(.u-no-visual)', wol.question_rank, wol.wol_ref)
          page.all(selector)
        else
          selector = format('#question_%02d_whole_question .answer_wrapper span.student_answer', wol.question_rank)
          wrapper_element = find_nth_or_fail(selector, wol.wol_ref - 1, wol)
          selector = 'span:not(.correct):not(.u-no-visual)'
          wrapper_element.all(selector)
        end
      end

      class FillInTheBlanksQuestionElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :rank, :page_object

        def initialize(page_object, rank)
          @page_object = page_object
          @rank = rank
        end

        def to_s
          "fib_question(#{rank})"
        end

        def mark
          selector = format('#activity_shell ol li[data-test-rank="%d"]', rank)
          page_object.mark_to_symbol(page_object.find_or_fail(selector, self)[:class])
        end

        def wol(ref)
          FillInTheBlanksWolElement.new(page_object, rank, ref)
        end

        def prompt_image(image_number)
          selector = format('#question_%02d_whole_question img', rank)
          page_object.find_nth_or_fail(selector, image_number - 1, self)
        end

        def prompt_text
          selector = format('#question_%02d_whole_question', rank)
          page_object.find_or_fail(selector, self).text
        end

        def table_prompts
          page_object.all(table_prompts_selector).map do |node|
            text = node.text
            # find direct children and remove their text content from the node text
            node.all(:xpath, './*').each do |child|
              text = text.partition(child.text).values_at(0, 2).join
            end
            text.strip
          end
        end

        def help_request(request_number)
          FillInTheBlanksQuestionHelpRequest.new(
            page_object, rank, request_number, :help_request
          )
        end

        def review_request(request_number)
          FillInTheBlanksQuestionHelpRequest.new(
            page_object, rank, request_number, :review_request
          )
        end

        private def table_prompts_selector
          case page_object.view
          when :submit, :accept, :decide, :retry, :preview
            format('#question_%02d_whole_question > div > table > tbody > tr > td', rank)
          else
            format('#question_%02d_whole_question > table > tbody > tr > td', rank)
          end
        end

        private def helpable_element(is_overlay = false)
          selector = is_overlay ? format('#overlay-question_%02d_whole_question', rank) : format('#question_%02d_whole_question', rank)
          page_object.find_or_fail(selector, self)
        end

        private def show_hide_help_requests_disclosure
          selector = format('#activity_shell ol li[data-test-rank="%d"] .test-help-request-disclosure', rank)
          page_object.find_or_fail(selector, "#{self}.help_request_disclosure")
        end
      end

      class FillInTheBlanksQuestionHelpRequest
        include ActivityTest::PageObjects::HelpRequestElementMethods
        attr_reader :request_number, :question_rank, :page_object, :request_type

        def initialize(page_object, question_rank, request_number, request_type)
          @page_object = page_object
          @question_rank = question_rank
          @request_number = request_number
          @request_type = request_type
        end

        def to_s
          if request_type == :help_request
            "fib_question(#{question_rank}).help_request(#{request_number})"
          else
            "fib_question(#{question_rank}).review_request(#{request_number})"
          end
        end

        private def help_request_container
          page_object.find_nth_or_fail(container_selector, request_number - 1, self)
        end

        private def container_selector
          if request_type == :help_request
            format('[data-helpable-id=question_%02d_whole_question].test-help-request-container.request_help',
                   question_rank)
          else
            format('[data-helpable-id=question_%02d_whole_question].test-help-request-container.request_review',
                   question_rank)
          end
        end
      end

      class FillInTheBlanksWolElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :question_rank, :wol_ref, :page_object

        def initialize(page_object, question_rank, wol_ref)
          @page_object = page_object
          @question_rank = question_rank
          @wol_ref = wol_ref
        end

        def to_s
          "question(#{question_rank}).wol(#{wol_ref})"
        end

        def has_no_input_field?
          selector = format('input#question_%02d_wol_%d', question_rank, wol_ref)
          page_object.page.has_no_selector?(selector, visible: true)
        end

        def input_field_text
          selector = format('input#question_%02d_wol_%d', question_rank, wol_ref)
          page_object.find_or_fail(selector, "#{self}.input_text").value
        end

        def choose_answer(text)
          selector = format('input#question_%02d_wol_%d', question_rank, wol_ref)
          page_object.find_or_fail(selector, self).set(text)
        end

        def submitted_tokens
          elements = page_object.fib_wol_submitted_token_elements(self)
          1.upto(elements.size).map do |token_number|
            FillInTheBlanksWolSubmittedTokenElement.new(page_object, question_rank, wol_ref, token_number)
          end
        end

        def submitted_token(token_number)
          FillInTheBlanksWolSubmittedTokenElement.new(page_object, question_rank, wol_ref, token_number)
        end

        def correct_answer_tokens
          selector = case page_object.view
                     when :retry
                       format('#question_%02d_whole_question .answer_wrapper .correct_answer span:not(.u-no-visual)', question_rank)
                     when :accept, :complete
                       format('#question_%02d_wol_%d .correct_answer span:not(.u-no-visual)', question_rank, wol_ref)
                     else
                       raise ArgumentError, "invalid view '#{page_object.view}'"
                     end
          elements = page_object.page.all(selector)
          elements.map { |element| element.text&.strip }
        end

        def best_answers
          selector = format('#question_%02d_wol_%d .best_answers span', question_rank, wol_ref)
          page_object.page.all(selector).map { |element| element.text&.strip }
        end

        def help_request(help_request_number)
          FillInTheBlanksWolHelpRequest.new(
            page_object, question_rank, wol_ref, help_request_number, :help_request
          )
        end

        def review_request(review_request_number)
          FillInTheBlanksWolHelpRequest.new(
            page_object, question_rank, wol_ref, review_request_number, :review_request
          )
        end

        private def helpable_element(is_overlay = false)
          selector = is_overlay ? format('#overlay-question_%02d_wol_%d', question_rank, wol_ref) : format('#question_%02d_wol_%d', question_rank, wol_ref)
          page_object.find_or_fail(selector, self)
        end

        private def show_hide_help_requests_disclosure
          # The disclosure is the same one than the disclosure of the question
          selector = format('#activity_shell ol li[data-test-rank="%d"] .test-help-request-disclosure', question_rank)
          page_object.find_or_fail(selector, "#{self}.help_request_disclosure")
        end
      end

      class FillInTheBlanksWolSubmittedTokenElement
        attr_reader :page_object, :question_rank, :wol_ref, :token_number

        def initialize(page_object, question_rank, wol_ref, token_number)
          @page_object = page_object
          @question_rank = question_rank
          @wol_ref = wol_ref
          @token_number = token_number
        end

        def to_s
          "question(#{question_rank}).wol(#{wol_ref}).submitted_token(#{token_number})"
        end

        def mark
          if element[:class].empty? || element[:class] == 'u-txt-bold'
            :none
          else
            page_object.mark_to_symbol(element[:class].split[0])
          end
        end

        def text
          if page_object.view == :accept
            # When the answer is not complete, the missing tokens are not
            # empty and have the color white, so let fix this
            element[:style].include?('color: white') ? '' : element.text
          else
            element.text
          end
        end

        def title
          title_to_symbol(element[:title])
        end

        private def title_to_symbol(title)
          case title
          when '' then :none
          when 'Incorrect or extra punctuation' then :incorrect_or_extra_punctuation
          when 'Incorrect or extra word' then :incorrect_or_extra_word
          when 'Missing word' then :missing_word
          when 'Incorrect accent or capitalization' then :incorrect_accent_or_capitalization
          else
            raise ArgumentError, "invalid title '#{title}'"
          end
        end

        private def element
          elements = page_object.fib_wol_submitted_token_elements(self)
          if elements.size <= token_number - 1
            raise ArgumentError, "Unable to find #{self}"
          end
          return elements[token_number - 1]
        end
      end

      class FillInTheBlanksWolHelpRequest
        include ActivityTest::PageObjects::HelpRequestElementMethods
        attr_reader :request_number, :question_rank, :page_object, :wol_ref, :request_type

        def initialize(page_object, question_rank, wol_ref, request_number, request_type)
          @page_object = page_object
          @question_rank = question_rank
          @wol_ref = wol_ref
          @request_number = request_number
          @request_type = request_type
        end

        def to_s
          if request_type == :help_request
            "fib_question(#{question_rank}).wol(#{wol_ref}).help_request(#{request_number})"
          else
            "fib_question(#{question_rank}).wol(#{wol_ref}).review_request(#{request_number})"
          end
        end

        private def help_request_container
          page_object.find_nth_or_fail(container_selector, request_number - 1, self)
        end

        private def container_selector
          if request_type == :help_request
            format('[data-helpable-id=question_%02d_wol_%d].test-help-request-container.help_request',
                   question_rank, wol_ref)
          else
            format('[data-helpable-id=question_%02d_wol_%d].test-help-request-container.request_review',
                   question_rank, wol_ref)
          end
        end
      end
    end
  end
end
