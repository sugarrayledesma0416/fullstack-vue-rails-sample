require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    # Wrapper methods that create a PageObject from the current activity
    # data and assign it to an instance variable which can then be used
    # by other helpers inside the block.
    def from_drop_down_question(rank)
      question = @page_object.drop_down_question(rank)
      if block_given?
        yield question
      else
        question
    end
    end

    module DropDownMethods
      def drop_down_question(rank)
        DropDownQuestionElement.new(self, rank)
      end

      # Private methods goes below
      class DropDownQuestionElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :rank, :page_object

        def initialize(page_object, rank)
          @page_object = page_object
          @rank = rank
        end

        def to_s
          "drop_down_question(#{rank})"
        end

        def mark
          page_object.mark_to_symbol(page_object.find_or_fail(mark_selector, self)[:class])
        end

        def drop_down_menus
          page_object.activity_data.question(rank).menus.map do |menu|
            DropDownMenuElement.new(page_object, rank, menu.ref)
          end
        end

        def drop_down_menu(menu_ref)
          DropDownMenuElement.new(page_object, rank, menu_ref)
        end

        def prompt_images
          selector = format('#question_%02d_whole_question img', rank)
          page_object.page.all(selector)
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
          DropDownQuestionHelpRequest.new(page_object, rank, request_number, :help_request)
        end

        def review_request(request_number)
          DropDownQuestionHelpRequest.new(page_object, rank, request_number, :review_request)
        end

        private def table_prompts_selector
          case page_object.view
          when :submit, :accept, :decide, :retry
            format('#question_%02d_whole_question div > table > tbody > tr > td', rank)
          else
            format('#question_%02d_whole_question table > tbody > tr > td', rank)
          end
        end

        private def mark_selector
          case page_object.view
          when :preview
            format('#question_%02d', rank)
          when :decide, :submit, :retry, :accept, :complete
            format('ol.answers > li[data-test-rank="%d"]', rank)
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end

        private def helpable_element(is_overlay = false)
          selector = is_overlay ? format('#overlay-question_%02d_whole_question', rank) : format('#question_%02d_whole_question', rank)
          page_object.find_or_fail(selector, self)
        end

        private def show_hide_help_requests_disclosure
          selector = format('#activity_shell ol.answers li[data-test-rank="%d"] .test-help-request-disclosure', rank)
          page_object.find_or_fail(selector, "#{self}.help_request_disclosure")
        end
      end

      class DropDownQuestionHelpRequest
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
            "drop_down_question(#{question_rank}).help_request(#{request_number})"
          else
            "drop_down_question(#{question_rank}).review_request(#{request_number})"
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

      class DropDownMenuElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :question_rank, :menu_ref, :page_object

        def initialize(page_object, question_rank, menu_ref)
          @page_object = page_object
          @question_rank = question_rank
          @menu_ref = menu_ref
        end

        def to_s
          "question(#{question_rank}).drop_down_menu(#{menu_ref})"
        end

        def mark
          case page_object.view
          when :decide then mark_for_decide_view
          when :submit then mark_for_submit_view
          when :retry then mark_for_retry_view
          when :accept then mark_for_accept_view
          when :complete then mark_for_complete_view
          else
            raise NotImplementedError, "Should not be called in view #{view}"
          end
        end

        def options
          page_object.activity_data.question(question_rank).menu(menu_ref).options.map do |option|
            DropDownMenuOptionElement.new(page_object, question_rank, menu_ref, option.number)
          end
        end

        def option(option_number)
          DropDownMenuOptionElement.new(page_object, question_rank, menu_ref, option_number)
        end

        def select_option(option_number)
          page_object.find_or_fail(buttonSelector, self).click
          page_object.find_or_fail(optionSelector(option_number), self).click
          #option(option_number).select
        end

        def text
          case page_object.view
          when :submit then text_for_submit_view
          when :retry then text_for_retry_view
          when :accept then text_for_accept_view
          when :complete then text_for_complete_view
          else
            raise NotImplementedError, "Should not be called in view #{page_object.view}"
          end
        end

        def buttonSelector
          format('#question_%02d_%d_dd_btn',
                question_rank, menu_ref)
        end

        def optionSelector(option_number)
          #format('select#question_%02d_%d > option[value="%d"]',
          format('.test-question_%02d_%d-listbox > ul > li[data-index="%d"]',
                 question_rank, menu_ref, option_number)
        end

        private def text_for_submit_view
          selector = format('span#question_%02d_%d', question_rank, menu_ref)
          page_object.find_or_fail(selector, self).text
        end

        private def correct_selector_for_retry_view
          format('#question_%02d_%d_correct_choice', question_rank, menu_ref)
        end

        private def incorrect_selector_for_retry_view
          format('#question_%02d_%d_incorrect_choice', question_rank, menu_ref)
        end

        private def menu_element_for_retry_view
          selector = format('#question_%02d_%d', question_rank, menu_ref)
          page_object.find_or_fail(selector, self)
        end

        private def text_for_retry_view
          if menu_element_for_retry_view['type'] == 'hidden'
            elements = page_object.all(correct_selector_for_retry_view, wait: 0)
            return elements[0].text if elements.size > 0
            elements = page_object.all(incorrect_selector_for_retry_view, wait: 0)
            return elements[0].text if elements.size > 0
            raise ArgumentError, "Unable to find text for '#{self}'"
          else
            raise ArgumentError, "Unable to find text for '#{self}': this menu " \
              "should not have any text"
          end
        end

        private def text_for_accept_view
          selector = format('#question_%02d_%d', question_rank, menu_ref)
          # When a menu is incorrect, there is 2 elements with this selector.
          # We only want the first one.
          page_object.find_first_or_fail(selector, self).text
        end

        private def text_for_complete_view
          selector = format('#question_%02d_%d', question_rank, menu_ref)
          # When a menu is incorrect, there is 2 elements with this selector.
          # We only want the first one.
          page_object.find_first_or_fail(selector, self).text
        end

        private def mark_for_decide_view
          selector = format('#question_%02d_%d_dd_btn', question_rank, menu_ref)
          # The mark of the menu is not in the dropdown element itself but in its
          # parent if not marked as blank
          element = page_object.find_or_fail(selector, self)
          parents = element.all(:xpath, './../../..', wait: 0)
          if !parents.empty? && parents[0].tag_name == 'span'
            return page_object.mark_to_symbol(parents[0][:class])
          else
            raise ArgumentError, "Unable to find mark for '#{menu_ref}'"
          end
        end

        private def mark_for_submit_view
          selector = format('span#question_%02d_%d', question_rank, menu_ref)
          page_object.mark_to_symbol(page_object.find_or_fail(selector, self)[:class])
        end

        private def mark_for_retry_view
          element = menu_element_for_retry_view
          if element['type'] == 'hidden'
            # When a menu is correct or incorrect, the element is hidden and the
            # mark can be deduced by the presence of the two following selectors
            if page_object.has_selector?(correct_selector_for_retry_view, wait: 0)
              return :correct
            elsif page_object.has_selector?(incorrect_selector_for_retry_view, wait: 0)
              return :incorrect
            else
              raise ArgumentError, "Unable to find mark for '#{self}'"
            end
          else
            # The menu's mark is in the parent element
            parents = element.all(:xpath, './../../../..', wait: 0)
            if !parents.empty? && parents[0].tag_name == 'span'
              return page_object.mark_to_symbol(parents[0][:class])
            else
              raise ArgumentError, "Unable to find mark for '#{menu}'"
            end
          end
        end

        private def mark_for_accept_view
          selector = format('#question_%02d_%d', question_rank, menu_ref)
          # When a menu is incorrect, there is 2 elements with this selector.
          # We only want the first one.
          page_object.mark_to_symbol(page_object.find_first_or_fail(selector, self)[:class])
        end

        private def mark_for_complete_view
          selector = format('#question_%02d_%d', question_rank, menu_ref)
          # When a menu is incorrect, there is 2 elements with this selector.
          # We only want the first one.
          page_object.mark_to_symbol(page_object.find_first_or_fail(selector, self)[:class])
        end

        def help_request(request_number)
          DropDownMenuHelpRequest.new(
            page_object, question_rank, menu_ref, request_number, :help_request
          )
        end

        def review_request(request_number)
          DropDownMenuHelpRequest.new(
            page_object, question_rank, menu_ref, request_number, :review_request
          )
        end

        private def helpable_element(is_overlay = false)
          selector = is_overlay ? format('#overlay-question_%02d_%d', question_rank, menu_ref) : format('#question_%02d_%d', question_rank, menu_ref)
          page_object.find_first_or_fail(selector, self)
        end

        private def show_hide_help_requests_disclosure
          selector = format(
            '#activity_shell ol.answers li[data-test-rank="%d"] .test-help-request-disclosure',
            question_rank
          )
          page_object.find_or_fail(selector, "#{self}.help_request_disclosure")
        end
      end

      class DropDownMenuHelpRequest
        include ActivityTest::PageObjects::HelpRequestElementMethods
        attr_reader :request_number, :menu_ref, :question_rank, :page_object, :request_type

        def initialize(page_object, question_rank, menu_ref, request_number, request_type)
          @request_number = request_number
          @page_object = page_object
          @menu_ref = menu_ref
          @question_rank = question_rank
          @request_type = request_type
        end

        def to_s
          if request_type == :help_request
            "drop_down_question(#{question_rank}).menu(#{menu_ref}).help_request(#{request_number})"
          else
            "drop_down_question(#{question_rank}).menu(#{menu_ref}).review_request(#{request_number})"
          end
        end

        private def help_request_container
          page_object.find_nth_or_fail(container_selector, request_number - 1, self)
        end

        private def container_selector
          if request_type == :help_request
            format('.test-help-request-container[data-helpable-id="question_%02d_%d"].help_request',
                            question_rank, menu_ref)
          else
            format('.test-help-request-container[data-helpable-id="question_%02d_%d"].request_review',
                            question_rank, menu_ref)
          end
        end
      end

      class DropDownMenuOptionElement
        attr_reader :question_rank, :menu_ref, :option_number, :page_object

        def initialize(page_object, question_rank, menu_ref, option_number)
          @page_object = page_object
          @question_rank = question_rank
          @menu_ref = menu_ref
          @option_number = option_number
        end

        def to_s
          "question(#{question_rank}).drop_down_menu(#{menu_ref}).option(#{option_number})"
        end

        def selected?
          page_object.find_or_fail(selector, self).checked? || page_object.find_or_fail(selector, self)['aria-selected'] == 'true'
        end

        def select
          page_object.find_or_fail(selector, self).select_option
        end

        private def selector
          #format('select#question_%02d_%d > option[value="%d"]',
          format('.test-question_%02d_%d-listbox > ul > li[data-index="%d"]',
                 question_rank, menu_ref, option_number)
        end
      end
    end
  end
end
