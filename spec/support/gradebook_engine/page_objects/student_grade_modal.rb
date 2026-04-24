module GradebookEngineTest
  module PageObjects
    class StudentGradeModal
      include Capybara::DSL

      LINK_LABELS = {
        grade_this_assignment: 'Grade this Assignment',
        change_earned_score: 'Change Earned Score',
        review_student_work: 'Review Student Work',
        accept_late_work: 'Accept Late Work',
        reset_student_work: 'Reset Student Work'
      }.freeze

      def initialize(student, activity)
        @student = student
        @activity = activity
      end

      def open
        page.find(open_modal_selector).click
      end

      def has_no_link_to_be_opened?
        page.has_no_selector?(open_modal_selector)
      end

      def close
        page.find('.test-modal-close').click
      end

      def click_link(link_id)
        modal_element.find('a', text: link_label(link_id), visible: true).click
      end

      def has_grade_this_assignment_link?
        has_link?(:grade_this_assignment)
      end

      def has_no_grade_this_assignment_link?
        has_no_link?(:grade_this_assignment)
      end

      def has_change_earned_score_link?
        has_link?(:change_earned_score)
      end

      def has_no_change_earned_score_link?
        has_no_link?(:change_earned_score)
      end

      def has_review_student_work_link?
        has_link?(:review_student_work)
      end

      def has_no_review_student_work_link?
        has_no_link?(:review_student_work)
      end

      def has_accept_late_work_link?
        has_link?(:accept_late_work)
      end

      def has_no_accept_late_work_link?
        has_no_link?(:accept_late_work)
      end

      def has_reset_student_work_link?
        has_link?(:reset_student_work)
      end

      def has_no_reset_student_work_link?
        has_no_link?(:reset_student_work)
      end

      private def has_link?(link_id)
        modal_element.has_selector?('a', text: link_label(link_id), visible: true)
      end

      private def has_no_link?(link_id)
        modal_element.has_no_selector?('a', text: link_label(link_id), visible: true)
      end

      private def open_modal_selector
        ".test-user_#{@student.id}_grade_#{@activity.id} a"
      end

      private def modal_element
        page.find('.test-modal-content')
      end

      private def link_label(link_id)
        LINK_LABELS[link_id]
      end
    end

    def for_student_grade_modal(student, activity)
      yield StudentGradeModal.new(student, activity)
    end
  end
end
