module SectionAnalytics
  module PracticeTest
    class SectionStudentsAggregator
      attr_reader :activities, :summative_activity, :assignments

      def initialize(section:, activities:, assignments:)
        @section = section
        @activities = activities
        @assignments = assignments
      end

      def student_rows
        @student_rows ||= students.map do |student|
          StudentRow.new(
            student: student,
            summative_activity: summative_activity,
            formative_activities: formative_activities,
            assignments: assignments
          )
        end
      end

      def summative_grade_for(student)
        @summative_activity_grades.student_grade(student)
      end

      def summative_grade_submitted_for(student)
        @summative_activity_grades.student_grade_submitted?(student)
      end

      def summative_activity_grades
        return if summative_activity.nil?

        @summative_activity_grades ||= SectionActivityGrades.new(@section, summative_activity)
      end

      def summative_activity
        @summative_activity ||= activities.find(&:diagnostic_v2_summative?)
      end

      def summative_concepts
        if summative_activity.present?
          summative_activity.study_plan_concepts.where(
            cms_revision_id: @summative_activity.cms_revision_id
          )
        else
          StudyPlanConcept.none
        end
      end

      def sort_by(&block)
        student_rows.sort_by! do |student_row|
          block.call(student_row.student_scores)
        end
      end

      def reverse
        student_rows.reverse!
      end

      def formative_activities
        @activities - [summative_activity]
      end

      private def students
        @students ||= @section.current_students_base
                        .includes(:attempts, readings: { recommendation: :study_plan_concept })
                        .order(:last_name)
      end
    end
  end
end
