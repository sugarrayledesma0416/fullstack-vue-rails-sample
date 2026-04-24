require 'support/activity_test/page_objects/helpable_item'

module ActivityTest
  module PageObjects
    def from_recording_v2_question(rank)
      question = @page_object.recording_v2_question(rank)
      if block_given?
        yield question
      else
        question
      end
    end

    module RecordingV2Methods
      def show_transcriptions
        find('.test-show_transcriptions', text: 'Show Audio Transcript').click
      end

      def hide_transcriptions
        find('.test-show_transcriptions', text: 'Hide Audio Transcript').click
      end

      def recording_v2_question(rank)
        RecordingV2QuestionElement.new(self, rank)
      end

      # Private methods goes below
      class RecordingV2QuestionElement
        include ActivityTest::PageObjects::HelpableItemElementMethods
        attr_reader :rank, :page_object

        def initialize(page_object, rank)
          @page_object = page_object
          @rank = rank
        end

        def to_s
          "recording_v2_question(#{rank})"
        end

        def mark
          page_object.mark_to_symbol(container[:class])
        end

        def prompt_text
          page_object.element_find_or_fail(
            container, '.prompt_body', "#{self}.prompt"
          ).text
        end

        def prompt_transcription
          page_object.element_find_or_fail(
            container, '.test-prompt_transcription', "#{self}.prompt_transcription"
          ).text
        end

        def has_no_prompt_transcription?
          container.has_no_selector?('.test-prompt_transcription', visible: true)
        end

        def button(type)
          MediaButton.new(self, type)
        end

        class MediaButton
          attr_accessor :button_type, :question

          def initialize(question, button_type)
            self.question = question
            self.button_type = button_type
          end

          def to_s
            "recording_v2_question(#{question.rank}).button_#{button_type}"
          end

          def not_exist?
            question.container.has_no_selector?(button_selector, visible: true)
          end

          def enabled?
            !disabled?
          end

          def disabled?
            button[:disabled] == 'true'
          end

          def active?
            button[:class]['is-active']
          end

          def loading?
            button[:class]['is-loading']
          end

          def click
            button.click
          end

          private def button
            question.page_object.element_find_or_fail(
              question.container, button_selector, self
            )
          end

          private def button_selector
            case button_type
            when :listen
              '.test-media-button-listen button'
            when :record
              '.test-media-button-speak button'
            when :review
              '.test-media-button-review button'
            when :answer
              '.test-media-button-answer button'
            when :compare
              '.test-media-button-compare button'
            else
              raise NotImplementedError, "Unknown button type '#{button_type}'"
            end
          end
        end

        def help_request(request_number)
          RecordingV2QuestionHelpRequest.new(page_object, rank, request_number, :help_request)
        end

        def review_request(request_number)
          RecordingV2QuestionHelpRequest.new(page_object, rank, request_number, :review_request)
        end

        private def helpable_element(is_overlay = false)
          selector = is_overlay ? format('#overlay-question_%d_whole_question', rank) : format('#question_%d_whole_question', rank)
          page_object.find_or_fail(selector, self)
        end

        private def show_hide_help_requests_disclosure
          selector = format(
            '#activity_shell li[data-test-rank="%d"] .test-help-request-disclosure',
            rank
          )
          page_object.find_or_fail(selector, "#{self}.help_request_disclosure")
        end

        def container
          selector = format('#activity_shell li[data-test-rank="%d"]', rank)
          page_object.find_or_fail(selector, self)
        end
      end

      class RecordingV2QuestionHelpRequest
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
            "recording_v2_question(#{question_rank}).help_request(#{request_number})"
          else
            "recording_v2_question(#{question_rank}).review_request(#{request_number})"
          end
        end

        private def help_request_container
          page_object.find_nth_or_fail(container_selector, request_number - 1, self)
        end

        private def container_selector
          if request_type == :help_request
            format(
              '#activity_shell li[data-test-rank="%d"] .test-help-request-container.request_help',
              question_rank
            )
          else
            format(
              '#activity_shell li[data-test-rank="%d"] .test-help-request-container.request_review',
              question_rank
            )
          end
        end
      end
    end
  end
end
