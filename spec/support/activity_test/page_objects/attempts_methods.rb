module ActivityTest
  module PageObjects
    module AttemptsMethods
      def attempts
        ActivityAttemptsElement.new(self)
      end

      def has_no_attempts?
        ActivityAttemptsElement.new(self).not_exist?
      end

      def has_been_viewed?
        ActivityAttemptsElement.new(self).viewed?
      end

      # Private methods goes below
      class ActivityAttemptsElement
        attr_reader :page_object
        def initialize(page_object)
          @page_object = page_object
        end

        def to_s
          'attempts counter'
        end

        def exist?
          page_object.has_selector?(selector)
        end

        def not_exist?
          page_object.has_no_selector?(selector)
        end

        def unlimited?
          element.text == 'unlimited attempts remaining'
        end

        def viewed?
          element.text.start_with?('VIEWED ON ')
        end

        def remaining
          if unlimited?
            -1
          else
            element.text.match(/([0-9]+) attempts? left/i) { |m| Integer(m[1]) }
          end
        end

        private def element
          page_object.find_or_fail(selector, self)
        end

        private def selector
          '.test-attempts-remaining'
        end
      end
    end
  end
end
