# Monkey patch of Capybara SelectorQuery class to raise an error when passing
# unused parameters.
# reference: http://millo.me/capybara-unused-parameters
module Capybara
  module Queries
    class SelectorQuery
      def warn(*messages)
        if messages.first.start_with?('Unused parameters')
          raise messages.first
        else
          super
        end
      end
    end
  end
end
