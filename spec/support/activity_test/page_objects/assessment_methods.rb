module ActivityTest
  module PageObjects
    # Wrapper methods that create a PageObject from the current assessment
    # section and assign it to an instance variable which can then be used
    # by other helpers inside the block.
    def from_assessment_section(rank)
      section = @page_object.assessment_section(rank)
      if block_given?
        yield section
      else
        section
      end
    end

    module AssessmentMethods
      def assessment_sections
        page.all('.assessment-section').map do |container|
          AssessmentSectionElement.new(self, container[:index].to_i)
        end
      end

      def assessment_section(rank)
        AssessmentSectionElement.new(self, rank)
      end

      # private methods goes below
      class AssessmentSectionElement
        # include Capybara::DSL
        # include CapybaraViewHelpers
        # include RspecJsCommonHelpers

        attr_reader :page_object, :section_number

        def initialize(page_object, section_number)
          @page_object = page_object
          @section_number = section_number
        end

        def exam_header
          container.find('.reference_diagnostic_header').text
        end

        def activity_type
          container.find('[data-question-type]')['data-question-type']
        end

        def multiple_choice_questions
          questions(ActivityTest::PageObjects::MultipleChoiceMethods::MultipleChoiceQuestionElement)
        end

        def drop_down_questions
          questions(ActivityTest::PageObjects::DropDownMethods::DropDownQuestionElement)
        end

        def fill_in_the_blanks_questions
          questions(ActivityTest::PageObjects::FillInTheBlanksMethods::FillInTheBlanksQuestionElement)
        end

        def open_ended_questions
          questions(ActivityTest::PageObjects::OpenEndedMethods::OpenEndedQuestionElement)
        end

        def true_false_enhanced_questions
          questions(ActivityTest::PageObjects::TrueFalseEnhancedMethods::TrueFalseEnhancedQuestionElement)
        end

        def recording_v2_questions
          questions(ActivityTest::PageObjects::RecordingV2Methods::RecordingV2QuestionElement)
        end

        private def questions(klass)
          container.all('[data-test-rank]').map do |question|
            klass.new(@page_object, question['data-test-rank'].to_i)
          end
        end

        def container
          page_object.find(".assessment-section[index='#{section_number}']")
        end
      end
    end
  end
end
