require 'support/capybara_view_helpers'
require 'support/rspec_js_common_helpers'
require 'support/feature_spec_scrollable'
require 'support/activity_test/page_objects/helpable_item'
require 'support/activity_test/page_objects/multiple_choice_methods'
require 'support/activity_test/page_objects/multiple_answer_methods'
require 'support/activity_test/page_objects/drop_down_methods'
require 'support/activity_test/page_objects/open_ended_methods'
require 'support/activity_test/page_objects/table_inline_open_ended_methods'
require 'support/activity_test/page_objects/fill_in_the_blanks_methods'
require 'support/activity_test/page_objects/attempts_methods'
require 'support/activity_test/page_objects/direction_line_methods'
require 'support/activity_test/page_objects/accent_bar_methods'
require 'support/activity_test/page_objects/vocab_list_v2_methods'
require 'support/activity_test/page_objects/true_false_enhanced_methods'
require 'support/activity_test/page_objects/recording_v2_methods'
require 'support/activity_test/page_objects/assessment_methods'
require 'support/activity_test/page_objects/ai_virtual_chat_methods'

module ActivityTest
  # Will encapsulate knowledge about mechanisms for interacting with activities
  # that vary from view to view. PageObject classes may have methods to
  # support various activity types.
  # Should generally have methods that return selectors or locators or
  # templates that can be sprintf'ed to create same.
  module PageObjects
    # Wrapper methods that create a PageObject from the current activity
    # data and assign it to an instance variable which can then be used
    # by other helpers inside the block.
    def for_preview_page(activity_data)
      @page_object = PreviewPageObject.new(activity_data)
      yield @page_object
    end

    def for_decide_page(activity_data)
      @page_object = DecidePageObject.new(activity_data)
      yield @page_object
    end

    def for_submit_page(activity_data)
      @page_object = SubmitPageObject.new(activity_data)
      yield @page_object
    end

    def for_retry_page(activity_data)
      @page_object = RetryPageObject.new(activity_data)
      yield @page_object
    end

    def for_accept_page(activity_data)
      @page_object = AcceptPageObject.new(activity_data)
      yield @page_object
    end

    def for_unsubmittable_page(activity_data)
      @page_object = UnsubmittablePageObject.new(activity_data)
      yield @page_object
    end

    def for_complete_page(activity_data)
      @page_object = CompletePageObject.new(activity_data)
      yield @page_object
    end

    def for_practice_page(activity_data)
      @page_object = PracticePageObject.new(activity_data)
      yield @page_object
    end

    def for_santillana_book_page(activity_data)
      @page_object = SantillanaBookPageObject.new(activity_data)
      yield @page_object
    end

    class BasePageObject
      include Capybara::DSL
      include CapybaraViewHelpers
      include RspecJsCommonHelpers
      include FeatureSpecScrollable
      include MultipleChoiceMethods
      include MultipleAnswerMethods
      include DropDownMethods
      include OpenEndedMethods
      include TableInlineOpenEndedMethods
      include FillInTheBlanksMethods
      include AttemptsMethods
      include DirectionLineMethods
      include AccentBarMethods
      include VocabListV2Methods
      include TrueFalseEnhancedMethods
      include RecordingV2Methods
      include AssessmentMethods
      include AIVirtualChatMethods

      attr_reader :activity_data, :view
      BUTTON_SELECTORS = {
        submit: '#_activity_submit',
        save: '#_activity_save',
        retry: '#_activity_retry',
        accept: '#_activity_accept',
        practice: '.c-activity-footer__actions a[data-button="practice"]',
        go_to_dashboard: '.c-activity-footer__actions a[data-button="return"]',
        answers: '.c-activity-footer__actions input[value=Answers]',
        check: '.c-activity-footer__actions input[value=Check]'
      }.freeze

      def initialize(view, activity_data)
        @view = view
        @activity_data = activity_data
      end

      def button(id)
        find_or_fail(BUTTON_SELECTORS[id], "button #{id}")
      end

      def activity_title
        find_or_fail('.test-activity-title', 'activity title').text.strip
      end

      def mark_to_symbol(mark)
        case mark.split.first
        when 'correct', 'answer_correct' then :correct
        when 'incorrect', 'answer_incorrect' then :incorrect
        when 'answersblank', 'answer_blank', nil then :blank
        when 'changed' then :changed
        when 'answer_correction' then :correction
        when 'partial' then :partial
        when 'pending' then :pending
        when 'missed_punctuation' then :missed_punctuation
        else
          raise ArgumentError, "invalid mark '#{mark}'"
        end
      end
    end

    class PreviewPageObject < BasePageObject
      def initialize(activity_data)
        super(:preview, activity_data)
      end

      def default_buttons
        if activity_data.activity.partner_chat? ||
           activity_data.activity.speech_rec_listen_repeat? ||
           activity_data.activity.ai_virtual_chat?
          [:submit]
        else
          [:save, :submit]
        end
      end
    end

    class DecidePageObject < BasePageObject
      def initialize(activity_data)
        super(:decide, activity_data)
      end

      def default_buttons
        [:save, :submit]
      end
    end

    class SubmitPageObject < BasePageObject
      def initialize(activity_data)
        super(:submit, activity_data)
      end

      def default_buttons
        [:retry, :accept]
      end
    end

    class RetryPageObject < BasePageObject
      def initialize(activity_data)
        super(:retry, activity_data)
      end

      def default_buttons
        [:save, :submit]
      end
    end

    class AcceptPageObject < BasePageObject
      def initialize(activity_data)
        super(:accept, activity_data)
      end

      def default_buttons
        [:practice, :go_to_dashboard]
      end
    end

    class UnsubmittablePageObject < BasePageObject
      def initialize(activity_data)
        super(:unsubmittable, activity_data)
      end

      def default_buttons
        [:go_to_dashboard]
      end
    end

    class CompletePageObject < BasePageObject
      def initialize(activity_data)
        super(:complete, activity_data)
      end

      def default_buttons
        [:go_to_dashboard]
      end
    end

    class PracticePageObject < BasePageObject
      def initialize(activity_data)
        super(:practice, activity_data)
      end

      def default_buttons
        %i[answers check]
      end
    end

    class SantillanaBookPageObject < BasePageObject
      def initialize(activity_data)
        super(:santillana_book, activity_data)
      end

      def default_buttons
        [:go_to_dashboard]
      end
    end
  end
end
