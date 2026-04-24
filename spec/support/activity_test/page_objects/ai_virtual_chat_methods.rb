require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    module AIVirtualChatMethods
      def from_ai_virtual_chat_app
        app = AIVirtualChatAppElement.new(self)
        if block_given?
          yield app
        else
          app
        end
      end

      # Private methods goes below
      class AIVirtualChatAppElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        include Capybara::DSL
        include CapybaraViewHelpers
        attr_reader :page_object

        def initialize(page_object)
          @page_object = page_object
        end

        def to_s
          'ai_virtual_chat_app'
        end

        def chat_messages
          page.all('.chat-message .message-content').map(&:text)
        end

        def settings_area
          SettingsArea.new(parent: self)
        end

        def for_settings_area
          yield settings_area
        end

        def pane_footer
          PaneFooter.new(parent: self)
        end

        def for_pane_footer
          yield pane_footer
        end

        def pretest_modal
          PretestModal.new(parent: self)
        end

        def for_pretest_modal
          yield pretest_modal
        end

        def start_activity
          start_button.click
        end

        def start_button
          find_or_fail(
            '.test-start-button',
            "#{self}.start_button"
          )
        end

        def restart_activity
          restart_activity_button.click
        end

        def restart_activity_button
          find_or_fail(
            '.restart-activity-button',
            "#{self}.restart_activity_button"
          )
        end

        def restart_activity_modal
          RestartActivityModal.new(parent: self)
        end

        def for_restart_activity_modal
          yield restart_activity_modal
        end

        def switch_to_speech
          find_or_fail(
            '.test-switch-to-speech-button',
            "#{self}.switch_to_speech_button"
          ).click
        end

        def switch_to_text
          find_or_fail(
            '.test-switch-to-text-button',
            "#{self}.switch_to_text_button"
          ).click
        end

        class SettingsArea
          include Capybara::DSL
          include CapybaraViewHelpers

          attr_reader :parent

          def initialize(parent:)
            @parent = parent
          end

          def to_s
            "#{parent}.settings_area"
          end

          def has_no_test_connection_button?
            parent.has_no_selector?(test_connection_button_selector)
          end

          def test_connection_button
            find_or_fail(
              test_connection_button_selector,
              "#{self}.test_connection_button",
              element: container
            )
          end

          def has_no_auto_play_audio_checkbox?
            parent.has_no_selector?(auto_play_audio_checkbox_selector)
          end

          def auto_play_audio
            auto_play_audio_checkbox.checked?
          end

          def auto_play_audio=(value)
            auto_play_audio_checkbox.set(value)
          end

          def auto_play_audio_checkbox
            find_or_fail(
              auto_play_audio_checkbox_selector,
              "#{self}.auto_play_audio_checkbox",
              element: container
            )
          end

          def has_no_play_all_button?
            parent.has_no_selector?(play_all_button_selector)
          end

          def play_all_button
            find_or_fail(
              play_all_button_selector,
              "#{self}.play_all_button",
              element: container
            )
          end

          private def test_connection_button_selector
            '.test-connection-button'
          end

          private def auto_play_audio_checkbox_selector
            '#auto-play-audio'
          end

          private def play_all_button_selector
            '.play-all-button'
          end

          private def container
            find_or_fail('.settings-area', self)
          end
        end

        class PaneFooter
          include Capybara::DSL
          include CapybaraViewHelpers

          attr_reader :parent

          def initialize(parent:)
            @parent = parent
          end

          def to_s
            "#{parent}.pane_footer"
          end

          def record_button
            find_or_fail(
              record_button_selector,
              "#{self}.record_button",
              element: container
            )
          end

          def has_no_record_button?
            parent.has_no_selector?(record_button_selector)
          end

          def message_input
            message_input_field.value
          end

          def message_input=(value)
            message_input_field.set(value)
          end

          def has_no_message_input_field?
            parent.has_no_selector?(message_input_field_selector)
          end

          def send_button
            find_or_fail(
              send_button_selector,
              "#{self}.send_button",
              element: container
            )
          end

          def has_no_send_button?
            parent.has_no_selector?(send_button_selector)
          end

          def send_message(message)
            self.message_input = message
            send_button.click
          end

          private def message_input_field
            find_or_fail(
              message_input_field_selector,
              "#{self}.message_input_field",
              element: container
            )
          end

          private def record_button_selector
            '.test-audio-record-button'
          end

          private def message_input_field_selector
            '.chat-text-input .text-input'
          end

          private def send_button_selector
            '.test-send-text-button'
          end

          private def container
            find_or_fail('.pane-footer', self)
          end
        end

        class PretestModal
          include Capybara::DSL
          include CapybaraViewHelpers

          attr_reader :parent

          def initialize(parent:)
            @parent = parent
          end

          def to_s
            "#{parent}.pretest_modal"
          end

          def continue_button
            find_or_fail(
              '.test-continue-btn',
              "#{self}.continue_button",
              element: container
            )
          end

          def continue
            continue_button.click
          end

          private def container
            find_or_fail(
              '.pretest-app .test-result-modal',
              "#{self}.container"
            )
          end
        end

        class RestartActivityModal
          include Capybara::DSL
          include CapybaraViewHelpers

          attr_reader :parent

          def initialize(parent:)
            @parent = parent
          end

          def to_s
            "#{parent}.restart_activity_modal"
          end

          def restart_button
            find_or_fail(
              '.test-confirm-button',
              "#{self}.restart_button",
              element: container
            )
          end

          def restart
            restart_button.click
          end

          def cancel_button
            find_or_fail(
              '.test-cancel-button',
              "#{self}.cancel_button",
              element: container
            )
          end

          def cancel
            cancel_button.click
          end

          private def container
            find_or_fail(
              '.restart-activity-form',
              "#{self}.container"
            )
          end
        end
      end
    end
  end
end
