module ActivityTest
  module PageObjects
    module HelpableItemElementMethods
      def helpable?
        element = helpable_element
        parents = element.all(:xpath, './/..', wait: 0)
        return !parents.empty? \
            && parents[0].tag_name == 'div' \
            && parents[0][:class].include?('helpable')
      end

      def select_as_helpable
        page_object.scroll_to(helpable_element(true))
        helpable_element(true).click
      end

      def show_help_requests
        disclosure = show_hide_help_requests_disclosure
        page_object.within(disclosure) do
          toggler = page_object.find('.c-disclosure__header')
          page_object.scroll_to(toggler)
          # Sometimes the disclosure does not expand when we click on it.
          # Don't know why... To fix that, we click on the toggler until
          # the aria is expanded.
          Waiter.new.wait do
            toggler.click if toggler['aria-expanded'] == 'false'
            toggler['aria-expanded'] == 'true'
          end
          # Then we wait for the container to be fully expanded by waiting for
          # the footer of all the request container to be visible.
          Waiter.new.wait do
            page_object.all(
              '.test-help_request_container_footer', visible: :all
            ).all?(&:visible?)
          end
        end
      end

      def hide_help_requests
        disclosure = show_hide_help_requests_disclosure
        page_object.within(disclosure) do
          toggler = page_object.find('.c-disclosure__header')
          page_object.scroll_to(toggler)
          # Click on the toggler until the aria is not expanded anymore.
          Waiter.new.wait do
            toggler.click if toggler['aria-expanded'] == 'true'
            toggler['aria-expanded'] == 'false'
          end
          # Wait for the container to be fully closed by waiting for the
          # footer of all the request container to not be visible.
          Waiter.new.wait do
            page_object.all(
              '.test-help-request-container', visible: :all
            ).none?(&:visible?)
          end
        end
      end
    end

    module HelpRequestElementMethods
      def remove
        help_request_container.find('.test-remove-request').click
      end

      def student_name
        help_request_container.find('.test-student-name').text
      end

      def comment
        help_request_container.find('.test-student-comment-text').text
      end
    end
  end
end
