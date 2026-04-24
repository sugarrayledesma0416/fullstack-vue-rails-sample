module GradebookEngineTest
  module PageObjects
    class GradingStylePageObject
      include Capybara::DSL
      include CapybaraViewHelpers

      GRADING_STYLE_LABELS = {
        student_by_student: 'Student by student',
        question_by_question: 'Question by question',
        spotcheck: 'Spotcheck Student Work'
      }.freeze
      GRADING_STYLE_LABELS_REV = GRADING_STYLE_LABELS.invert.freeze

      def available_grading_styles
        all(grading_style_label_selector).map do |label|
          GRADING_STYLE_LABELS_REV[label.text]
        end
      end

      def grading_style=(style)
        find(grading_style_label_selector, text: GRADING_STYLE_LABELS[style]).click
      end

      def ai_assisted_grading=(value)
        find('label', text: value ? 'Yes' : 'No').click
      end

      def show_auto_graded_questions
        check(auto_graded_questions_selector)
        # Only wait for the container if we're dealing with auto-graded questions
        page.find('.sbs_sub_activity_container.auto-graded:not(.hidden_helper)', wait: 10) if has_selector?('.sbs_sub_activity_container.auto-graded')
      end

      def hide_auto_graded_questions
        uncheck(auto_graded_questions_selector)
      end

      def start_grading
        click_on('start grading')
      end

      private def grading_style_label_selector
        '#grading_style_form label'
      end

      private def auto_graded_questions_selector
        'Show auto-graded questions?'
      end
    end

    def for_grading_style_page_object
      @page_object = GradingStylePageObject.new
      yield @page_object
    end

    class StudentAnswerPageObject
      include Capybara::DSL
      include CapybaraViewHelpers

      attr_reader :question, :student

      def initialize(question, student)
        @question = question
        @student = student
      end

      def to_s
        "question(#{question}).student(#{student.id}).answer"
      end

      def not_exist?
        page.has_no_selector?(container_selector)
      end

      def exist?
        page.has_selector?(container_selector)
      end

      def score
        score_element.value
      end

      def score=(new_score)
        # Setting the value of an input fields uses the sendKeys() method,
        # that sometimes doesn't enter all the characters from string:
        # https://bugs.chromium.org/p/chromedriver/issues/detail?id=1771
        # As a workaround we use a a loop that doesn't exit until the field
        # contains the right characters
        loop do
          score_element.set(new_score)
          break if score == new_score.to_s
        end
      end

      def rubric_score(new_score, method)
        # Setting the value of an input fields uses the sendKeys() method,
        # that sometimes doesn't enter all the characters from string:
        # https://bugs.chromium.org/p/chromedriver/issues/detail?id=1771
        # As a workaround we use a a loop that doesn't exit until the field
        # contains the right characters

        if method == 'rubric'
          rubric_score_elements.each do |elm|
            loop do
              elm.set(new_score)
              break if elm.value == new_score.to_s
            end
          end
        else
          manual_input = page.find("input#manual-grading-score-user-#{student.id}")
          loop do
            manual_input.set(new_score)
            break if manual_input.value == new_score.to_s
          end
        end
      end

      def text_response
        StudentTextResponse.new(parent: self)
      end

      def ai_panel
        AiSuggestionPanelElement.new(parent: self)
      end

      def for_ai_panel
        yield ai_panel
      end

      def for_text_response
        yield text_response
      end

      def audio_response
        StudentAudioResponse.new(self, question, student)
      end

      def for_audio_response
        yield audio_response
      end

      def matching_response
        SmartbookMatchingResponse.new(self, question, student)
      end

      def for_matching_response
        yield matching_response
      end

      def drawing_response
        SmartbookDrawingResponse.new(self, question, student)
      end

      def for_drawing_response
        yield drawing_response
      end

      def instructor_comment
        instructor_comment_element.value
      end

      def instructor_comment=(value)
        instructor_comment_element.set(value)
      end

      private def instructor_comment_element
        find_or_fail(
          '.instructor_comment_input',
          "#{self}.instructor_comment",
          element: container
        )
      end

      private def score_element
        selector = ".c-grading-sidebar input#score_for_#{question}_student_#{student.id}"
        element_find_or_fail(container, selector, "#{self}.score")
      end

      private def rubric_score_elements
        selectors = ["#criteria-0-#{student.id}", "#criteria-1-#{student.id}", "#criteria-2-#{student.id}"]
        selectors.map do |selector|
          element_find_or_fail(container, selector, "#{self}.score")
        end
      end

      def container
        find_or_fail(container_selector, self)
      end

      private def container_selector
        "#answer_container_#{question}_student_#{student.id}"
      end

      # This class represents a Froala editor instance
      class StudentTextResponse
        include Capybara::DSL
        include CapybaraViewHelpers

        attr_reader :parent

        def initialize(parent:)
          @parent = parent
        end

        def to_s
          "#{parent}.text_response"
        end

        def container
          find_or_fail(
            '.student_response_area',
            self,
            element: parent.container
          )
        end

        def inline_comments
          textarea.all(
            'span.js-comment-inline:not([data-ai-grading-suggestion-id])'
          ).map do |element|
            InlineCommentElement.new(parent: self, element:)
          end
        end

        def new_inline_comment
          # Click on the editor text to unable the icon bar
          textarea.click
          toolbar.find('button[data-cmd="commentInline"]').click
        end

        def grading_suggestion_comments
          textarea.all('span.js-comment-inline[data-ai-grading-suggestion-id]').map do |element|
            id = element['data-ai-grading-suggestion-id'].to_i
            AiGradingSuggestionComment.new(parent: self, element:, id:)
          end
        end

        class AiGradingSuggestionComment
          include Capybara::DSL
          include CapybaraViewHelpers

          attr_reader :parent, :id, :element

          def initialize(parent:, element:, id:)
            @parent = parent
            @element = element
            @id = id
          end

          def to_s
            "#{parent}.ai_grading_suggestion_comment(#{id})"
          end

          def comment
            element['data-comment-inline']
          end
        end

        class InlineCommentElement
          include Capybara::DSL
          include CapybaraViewHelpers

          attr_reader :parent, :element

          def initialize(parent:, element:)
            @parent = parent
            @element = element
          end

          def to_s
            "#{parent}.ai_grading_suggestion_comment"
          end

          def comment
            element['data-comment-inline']
          end
        end

        def grading_suggestion_comment(id)
          find_or_fail(
            %(span.js-comment-inline[data-ai-grading-suggestion-id="#{id}"]),
            "#{self}.grading_suggestion_comment(#{id})",
            element: textarea
          )
        end

        def edit_comment_popup
          EditCommentPopup.new(parent: self)
        end

        def for_edit_comment_popup
          yield edit_comment_popup
        end

        private def toolbar
          find_or_fail(
            '.fr-toolbar',
            "#{self}.toolbar",
            element: container
          )
        end

        private def textarea
          find_or_fail(
            '.fr-wrapper',
            "#{self}.textarea",
            element: container
          )
        end

        class EditCommentPopup
          include Capybara::DSL
          include CapybaraViewHelpers

          attr_reader :parent

          def initialize(parent:)
            @parent = parent
          end

          def to_s
            "#{parent}.edit_comment_popup"
          end

          def comment
            comment_element.value
          end

          def comment=(value)
            comment_element.set(value)
          end

          def delete
            container.click_button('Delete')
          end

          def save
            container.click_button('Save')
          end

          def close
            find_or_fail(
              'button[title="Close"]',
              "#{self}.close_button",
              element: container
            ).click
          end

          def container
            find_or_fail(
              '.js-fr-custom-popup',
              self,
              element: parent.container
            )
          end

          private def comment_element
            find_or_fail(
              '.js-comment-inline-text',
              "#{self}.comment",
              element: container
            )
          end
        end
      end

      class AiSuggestionPanelElement
        include Capybara::DSL
        include CapybaraViewHelpers

        delegate :visible?, to: :container

        attr_reader :parent

        def initialize(parent:)
          @parent = parent
        end

        def to_s
          "#{parent}.ai_suggestion_panel"
        end

        def container
          find_or_fail(
            '.foil-panel.grading-suggestions-app',
            self,
            element: parent.container
          )
        end

        def suggestions
          container.all('.suggestions .grading-suggestion .suggestion').map do |element|
            AiGradingSuggestionElement.new(element:, id: element[:id].to_i)
          end
        end

        def suggestion(id:)
          element = find_or_fail(
            ".suggestions .grading-suggestion .suggestion[id='#{id}']",
            "#{self}.suggestion(#{id})",
            element: container
          )
          AiGradingSuggestionElement.new(element:, id:)
        end

        def overall_comments
          container.all('.suggestions .overall-feedback .suggestion').map do |element|
            AiOverallCommentElement.new(element:, id: element[:id].to_i)
          end
        end

        def overall_comment(id:)
          element = find_or_fail(
            ".suggestions .overall-feedback .suggestion[id='#{id}']",
            "#{self}.overallComment(#{id})",
            element: container
          )
          AiOverallCommentElement.new(element:, id:)
        end

        def open_flag_modal
          find_or_fail(
            '.flag-icon',
            "#{self}.open_flag_modal",
            element: container
          ).click
        end

        def flag_modal
          AiFlagModal.new(parent: self)
        end

        def for_flag_modal
          yield flag_modal
        end

        class AiFlagModal
          include Capybara::DSL
          include CapybaraViewHelpers

          attr_reader :parent

          delegate :visible?, to: :container

          def initialize(parent:)
            @parent = parent
          end

          def to_s
            "#{parent}.ai_flag_modal"
          end

          def container
            find_or_fail(
              '.flagging-dialog',
              self,
              element: parent.container
            )
          end

          def submit_button
            find_or_fail(
              '.test-submit-button',
              "#{self}.submit_button",
              element: container
            )
          end

          def submit
            submit_button.click
          end

          def grading_suggestions
            container.all('.grading-suggestion').map do |element|
              AiFlagGradingSuggestionElement.new(element:, id: element['id'].to_i)
            end
          end

          def grading_suggestion(id:)
            element = find_or_fail(
              %(.grading-suggestion[id="#{id}"]),
              "#{self}.grading_suggestion(#{id})",
              element: container
            )
            AiFlagGradingSuggestionElement.new(element:, id:)
          end

          def for_grading_suggestion(id:)
            yield grading_suggestion(id:)
          end

          def overall_comments
            container.all('.overall-comment').map do |element|
              AiFlagOverallCommentElement.new(element:, id: element['id'].to_i)
            end
          end

          def overall_comment(id:)
            element = find_or_fail(
              %(.overall-comment[id="#{id}"]),
              "#{self}.overall_comment(#{id})",
              element: container
            )
            AiFlagOverallCommentElement.new(element:, id:)
          end

          def for_overall_comment(id:)
            yield overall_comment(id:)
          end

          def additional_feedback
            additional_feedback_element.value
          end

          def additional_feedback=(value)
            additional_feedback_element.set(value)
          end

          private def additional_feedback_element
            find_or_fail(
              '.additional-feedback',
              "#{self}.additional_feedback",
              element: container
            )
          end

          # Represents a suggestion (grading suggestion or an overall comment)
          # in the Flagging dialog.
          class AiFlagSuggestionElement
            attr_reader :element, :id

            def initialize(element:, id:)
              @element = element
              @id = id
            end

            def label
              element.find('.suggestion-text .test-text').text
            end

            def comment
              selected? ? comment_element.value : ''
            end

            def comment=(value)
              comment_element.set(value)
            end

            def selected?
              checkbox_element.checked?
            end

            def select
              checkbox_element.check
            end

            def unselect
              checkbox_element.uncheck
            end

            def rating_category=(value)
              element.find('select > option', text: value).select_option
            end

            private def comment_element
              element.find('.suggestion-rating-comment')
            end

            private def checkbox_element
              element.find('.suggestion-checkbox input')
            end

            private def rating_categories_element
              element.find('select')
            end
          end

          class AiFlagGradingSuggestionElement < AiFlagSuggestionElement
          end

          class AiFlagOverallCommentElement < AiFlagSuggestionElement
          end
        end

        class AiSuggestionElement
          attr_reader :element, :id

          def initialize(element:, id:)
            @element = element
            @id = id
          end

          def label
            element.find('.suggestion-text').text
          end

          def accept
            element.find('.plus-icon').click
          end

          def reject
            element.find('.x-icon').click
          end

          def accepted?
            element.has_selector?('.x-icon')
          end

          def rejected?
            element.has_selector?('.plus-icon')
          end

          def edited?
            element[:class].squish.split.include?('suggestion-edited')
          end
        end

        class AiGradingSuggestionElement < AiSuggestionElement
        end

        class AiOverallCommentElement < AiSuggestionElement
        end
      end

      class StudentAudioResponse
        attr_reader :page_object, :question, :student

        def initialize(page_object, question, student)
          @page_object = page_object
          @question = question
          @student = student
        end

        def to_s
          "question(#{question}).student(#{student.id}).audio_response"
        end

        def source
          player['src']
        end

        def player
          selector = "#student_#{student.id}_#{question}_student_response audio"
          page_object.find_or_fail(selector, self).tap do |element|
            def element.disabled?
              self['disabled'] == 'true'
            end
          end
        end
      end

      class SmartbookMatchingResponse
        attr_reader :page_object, :question, :student

        def initialize(page_object, question, student)
          @page_object = page_object
          @question = question
          @student = student
        end

        def to_s
          "question(#{question}).student(#{student.id}).smartbook_matching_response"
        end

        def entry(number)
          selector = "#student_#{student.id}_#{question}_student_response .test-matching-response"
          row = page_object.find_nth_or_fail(selector, number - 1, self)
          Entry.new(row)
        end

        class Entry
          attr_reader :element

          def initialize(element)
            @element = element
          end

          def prompt
            element.find('td.matching_prompt').text
          end

          def correct_answer
            element.find('td.matching_correct_answer').text
          end

          def student_answer
            element.find('td.matching_student_answer').text
          end
        end
      end

      class SmartbookDrawingResponse
        attr_reader :page_object, :question, :student

        def initialize(page_object, question, student)
          @page_object = page_object
          @question = question
          @student = student
        end

        def to_s
          "question(#{question}).student(#{student.id}).smartbook_drawing_response"
        end

        def image
          selector = "#student_#{student.id}_#{question}_student_response .test-drawing_response"
          page_object.find_or_fail(selector, self)
        end

        def image_src
          image['src']
        end
      end
    end

    class GradingBasePageObject
      include Capybara::DSL
      include CapybaraViewHelpers

      BUTTON_SELECTORS = {
        previous: 'input[value="< Save & Previous"]',
        next: 'input[value="Save & Next >"]',
        done: 'input[value="Save & Done"]'
      }.freeze

      def student_answer(question, student)
        StudentAnswerPageObject.new(question, student)
      end

      def for_student_answer(question, student)
        yield student_answer(question, student)
      end

      def button(id)
        find_or_fail(BUTTON_SELECTORS[id], "button #{id}").tap do |element|
          def element.click
            # Click button does not work consistently. It's even worse in
            # non-headless mode. It seems to be a problem with the chromedriver.
            # We redefined the click method as a workaround for now.
            # References:
            # https://github.com/SeleniumHQ/selenium/issues/4075
            # https://bugs.chromium.org/p/chromedriver/issues/detail?id=2452&q=emulation&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
            script = 'arguments[0].click();'
            Capybara.current_session.driver.browser.execute_script(script, self.native)
          end
        end
      end
    end

    class GradingStudentByStudentPageObject < GradingBasePageObject
      def to_s
        'Grading student by student page'
      end

      def select_student(student)
        page.find('#student_dropdown_menu option', text: student.full_name).select_option
      end

      def selected_student
        selector = '#student_dropdown_menu option[selected="selected"]'
        find_or_fail(selector, "#{self}.student_dropdown").text
      end

      def selectable_students
        page.all('#student_dropdown_menu option').map(&:text)
      end

      def select_last_student
        page.all('#student_dropdown_menu option').last.select_option
      end
    end

    class GradingQuestionByQuestionPageObject < GradingBasePageObject
      def to_s
        'Grading question by question page'
      end

      def select_question(question)
        page.find('select.js-jump-to option', text: question).select_option
      end

      def selected_question
        selector = 'select.js-jump-to option[selected="selected"]'
        find_or_fail(selector, "#{self}.question_dropdown").text
      end

      def selectable_questions
        all('select.js-jump-to option').map(&:text)
      end
    end

    def expect_grading_page_to_have_buttons(pobject, buttons)
      GradingBasePageObject::BUTTON_SELECTORS.each do |id, selector|
        if buttons.include?(id)
          expect(page).to have_selector(selector)
        else
          expect(page).to have_no_selector(selector)
        end
      end
    end

    def for_grading_student_by_student
      @page_object = GradingStudentByStudentPageObject.new
      yield @page_object
    end

    def for_grading_question_by_question
      @page_object = GradingQuestionByQuestionPageObject.new
      yield @page_object
    end

    def for_grading_assignment
      @page_object = GradingStudentByStudentPageObject.new
      yield @page_object
    end

    def click_button_expect_alert(button_id, alert_msg)
      with_element(@page_object.button(button_id)) do |button|
        expect(
          accept_alert { button.click }
        ).to start_with(alert_msg)
      end
    end

    def select_student_expect_alert(student, alert_msg)
      expect(
        accept_alert do
          @page_object.select_student(student)
        end
      ).to start_with(alert_msg)
    end

    def select_question_expect_alert(question, alert_msg)
      expect(
        accept_alert do
          @page_object.select_question(question)
        end
      ).to start_with(alert_msg)
    end

    class GradingSpotcheckStudentSelectionPageObject
      include Capybara::DSL
      include CapybaraViewHelpers

      SPOTCHECK_STYLE_IDS = {
        random: 'spotcheck_style_random',
        outliers: 'spotcheck_style_outliers',
        manual: 'spotcheck_style_manual'
      }.freeze
      SPOTCHECK_STYLE_IDS_REV = SPOTCHECK_STYLE_IDS.invert.freeze

      def to_s
        'grading_spotcheck_student_selection'
      end

      def spotcheck_style
        id = find_or_fail(
          'input[name="spotcheck_style"][checked="checked"]',
          'spotcheck_style'
        )['id']
        SPOTCHECK_STYLE_IDS_REV[id]
      end

      def spotcheck_style=(style)
        id = SPOTCHECK_STYLE_IDS[style]
        find_or_fail("##{id}", 'spotcheck_style').click
      end

      def random_students
        student_row_selector = '#random_student_list table tr.students'
        all(student_row_selector, visible: :all).map do |row|
          StudentRow.new(student_row_selector, row['id'])
        end
      end

      def outliers_students
        student_row_selector = '#outliers_student_list table tr.students'
        all(student_row_selector, visible: :all).map do |row|
          StudentRow.new(student_row_selector, row['id'])
        end
      end

      def manual_students
        student_row_selector = '#manual_student_list table tr.students'
        all(student_row_selector, visible: :all).map do |row|
          StudentRow.new(student_row_selector, row['id'])
        end
      end

      def select_all_students
        find('.student_list #check_all', visible: true).set(true)
      end

      def unselect_all_students
        find('.student_list #check_all', visible: true).set(false)
      end

      def start_grading_button
        find('.student_list #spot_check_submit_button', visible: true)
      end

      class StudentRow
        include Capybara::DSL
        include CapybaraViewHelpers

        attr_accessor :row_selector, :student_id

        def initialize(row_selector, student_id)
          @row_selector = row_selector
          @student_id = student_id
        end

        def to_s
          student_id
        end

        def check
          element_find_or_fail(student_row, 'input[type="checkbox"]', "#{self}.checkbox").set(true)
        end

        def uncheck
          element_find_or_fail(student_row, 'input[type="checkbox"]', "#{self}.checkbox").set(false)
        end

        def selected?
          student_row.find('input[type="checkbox"]', visible: :all).checked?
        end

        def checkbox_visible?
          student_row.find('input[type="checkbox"]', visible: :all).visible?
        end

        def name
          student_row.find('label').text
        end

        def visible?
          student_row.find('label', visible: :all).visible?
        end

        private def student_row
          find("#{row_selector}##{student_id}", visible: :all)
        end
      end
    end

    def for_grading_spotcheck_student_selection
      @page_object = GradingSpotcheckStudentSelectionPageObject.new
      yield @page_object
    end

    class GradingSpotcheckConfirmationModal
      include Capybara::DSL
      include CapybaraViewHelpers

      def grant_grade
        check('grant_grade', allow_label_click: true)
      end

      def comment=(value)
      end

      def finish_spotchecking
        find('.ui-dialog input[value="Finish Spotchecking"]').click
      end
    end

    def for_grading_spotcheck_confirmation_modal
      yield GradingSpotcheckConfirmationModal.new
    end
  end
end
