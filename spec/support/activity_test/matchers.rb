module ActivityTest
  module Matchers
    # Usage:
    #   expect(object).to be_marked(:correct)
    #   expect(object).not_to be_marked(:blank)
    #   expect(object).to be_marked('arbitrary string')
    # `object` must be an instance that responds to a `.mark` method, and that method
    #  must return a value of the same type as the specified expected mark
    def be_marked(expected)
      BeMarked.new(expected)
    end

    def all_be_marked(expected)
      AllBeMarked.new(expected)
    end

    def be_editable
      BeEditable.new(nil)
    end

    def all_be_editable
      AllBeEditable.new(nil)
    end

    def be_uneditable
      BeUneditable.new(nil)
    end

    def all_be_uneditable
      AllBeUneditable.new(nil)
    end

    def all_be_unselected
      AllBeUnselected.new(nil)
    end

    class Matcher
      include RSpec::Matchers::Composable

      attr_reader :failure_message, :failure_message_when_negated

      def initialize(expected)
        @expected = expected
      end
    end

    class BeMarked < Matcher
      def matches?(actual)
        actual_mark = actual.mark
        if actual_mark == @expected
          return true
        else
          @failure_message = "Expected #{actual} to be marked '#{@expected}' " \
            "but was marked '#{actual_mark}'"
          return false
        end
      end

      def does_not_match?(actual)
        actual_mark = actual.mark
        if actual_mark == @expected
          @failure_message_when_negated = "Expected #{actual} not to be marked '#{@expected}'"
          return false
        else
          return true
        end
      end
    end

    class AllBeMarked < Matcher
      # This matcher checks if all the elements are marked `@expected`
      # One can specify a different mark for some elements using the exception list.
      def matches?(actual)
        # Get the exception list if any
        exceptions = @exceptions || {}
        actual.each.with_index(1) do |element, index|
          actual_mark = element.mark
          # If this element is in the exception list, use this mark else use the `@expected`
          expected_mark = exceptions.fetch(index, @expected)
          if actual_mark != expected_mark
            @failure_message =
              "Expected #{element} to be marked '#{expected_mark}' but " \
              "was marked '#{actual_mark}'"
            return false
          end
        end
        true
      end

      # Set the exception list. It must be a hash where each key/value pair
      # representis an element and its mark
      def except(exceptions)
        @exceptions = exceptions
        self
      end

      def does_not_match?(actual)
        raise NotImplementedError,
        '`expect().not_to all_be_marked( matcher )` is not supported.'
      end
    end

    class BeEditable < Matcher
      def matches?(actual)
        if actual.editable?
          return true
        else
          @failure_message = "Expected #{actual} to be editable"
          return false
        end
      end

      def does_not_match?(actual)
        raise NotImplementedError,
        '`expect().not_to be_editable` is not supported. Please use `expect().to be_uneditable`'
      end
    end

    class AllBeEditable < Matcher
      def matches?(actual)
        actual.each do |element|
          if !element.editable?
            @failure_message = "Expected #{element} to be editable"
            return false
          end
        end
        true
      end

      def does_not_match?(actual)
        raise NotImplementedError,
        '`expect().not_to all_be_editable` is not supported. Please use `expect().to all_be_uneditable`'
      end
    end

    class BeUneditable < Matcher
      def matches?(actual)
        if actual.uneditable?
          return true
        else
          @failure_message = "Expected #{actual} to be uneditable"
          return false
        end
      end

      def does_not_match?(actual)
        raise NotImplementedError,
        '`expect().not_to be_uneditable` is not supported. Please use `expect().to be_editable`'
      end
    end

    class AllBeUneditable < Matcher
      def matches?(actual)
        actual.each do |element|
          if !element.uneditable?
            @failure_message = "Expected #{element} not to be editable"
            return false
          end
        end
        true
      end

      def does_not_match?(actual)
        raise NotImplementedError,
        '`expect().not_to all_be_uneditable` is not supported. Please use `expect().to all_be_editable`'
      end
    end

    class AllBeUnselected < Matcher
      def matches?(actual)
        actual.each do |element|
          if element.selected?
            @failure_message = "Expected #{element} not to be selected"
            return false
          end
        end
        true
      end

      def does_not_match?(actual)
        raise NotImplementedError,
        '`expect().not_to all_be_unselected` is not supported.'
      end
    end
  end
end
