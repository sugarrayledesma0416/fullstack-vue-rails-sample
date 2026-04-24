require 'support/activity_test/activity_data/activity_with_questions'

module ActivityTest
  module ActivityData
    class SmartBook < BaseActivity
      def initialize(activity)
        super(activity, nil)
      end
    end
  end
end
