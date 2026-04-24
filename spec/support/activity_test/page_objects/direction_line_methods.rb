require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    def from_direction_line
      direction_line = @page_object.direction_line
      if block_given?
        yield direction_line
      else
        direction_line
      end
    end

    module DirectionLineMethods
      def direction_line
        DirectionLineElement.new(self)
      end

      # Private methods goes below
      class DirectionLineElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :page_object
        def initialize(page_object)
          @page_object = page_object
        end

        def to_s
          'direction_line'
        end

        def text
          selector = '#direction_line.c-activity-context__directions'
          page_object.find_or_fail(selector, "#{self}.direction_line").text.strip
        end

        def select
          page_object.find_or_fail(helpable_element_selector, self).click
        end

        def help_request(help_request_number)
          DirectionLineHelpRequest.new(page_object, help_request_number)
        end

        private def helpable_element(is_overlay = false)
          if is_overlay
            page_object.find_or_fail(overlay_element_selector, self)
          else
            page_object.find_or_fail(helpable_element_selector, self)
          end
        end

        private def overlay_element_selector
          '#overlay-direction_line'
        end

        private def helpable_element_selector
          selector = '#direction_line.c-activity-context__directions'
        end

        private def show_hide_help_requests_disclosure
          # The plus sign means select elements immediately after element on the left.
          # The new activity shell markup takes the help requests next to the description area.
          selector = 'div.description-area + div .test-help-request-disclosure'
          page_object.find_or_fail(selector, "#{self}.help_request_disclosure")
        end
      end

      class DirectionLineHelpRequest
        include ActivityTest::PageObjects::HelpRequestElementMethods
        attr_reader :help_request_number, :page_object

        def initialize(page_object, help_request_number)
          @page_object = page_object
          @help_request_number = help_request_number
        end

        def to_s
          "direction_line.help_request(#{help_request_number})"
        end

        private def help_request_container
          # The plus sign means select elements immediately after element on the left.
          # The new activity shell markup takes the help requests next to the description area.
          selector = 'div.description-area + div .test-help-request-disclosure div.test-help-request-container'
          page_object.find_nth_or_fail(selector, help_request_number - 1, self)
        end
      end
    end
  end
end
