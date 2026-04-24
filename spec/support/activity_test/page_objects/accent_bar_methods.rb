module ActivityTest
  module PageObjects
    module AccentBarMethods
      def accent_bar
        AccentBarElement.new(self)
      end

      # Private methods goes below
      class AccentBarElement
        attr_reader :page_object

        def initialize(page_object)
          @page_object = page_object
        end

        def to_s
          'accent_bar'
        end

        def exist?
          page_object.has_selector?('#accent_bar')
        end

        def switch_to_upper_case
          page_object.find_or_fail(upper_case_toggler_selector, self).set(true)
        end

        def switch_to_lower_case
          page_object.find_or_fail(upper_case_toggler_selector, self).set(false)
        end

        def upper_case?
          page_object.find_or_fail(upper_case_toggler_selector, self).checked?
        end

        def lower_case?
          !upper_case?
        end

        # Return an array containing all the button of the accent bar
        def buttons
          if lower_case?
            page_object.find_or_fail('#accent_bar #accent_lower', self).all('button')
          else
            page_object.find_or_fail('#accent_bar #accent_caps', self).all('button')
          end
        end

        private def upper_case_toggler_selector
          '#accent_bar #caps_check'
        end
      end
    end
  end
end
