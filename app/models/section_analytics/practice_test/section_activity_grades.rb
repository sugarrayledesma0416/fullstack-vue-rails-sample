module SectionAnalytics
  module PracticeTest
    class SectionActivityGrades
      attr_accessor :activity

      delegate :content_object, :study_plan_concepts, to: :activity

      def initialize(section, activity)
        @section = section
        @activity = activity
        @student_grade_hash = {}
      end

      def student_grade(student)
        if @student_grade_hash[student.id]
          @student_grade_hash[student.id].result
        else
          student_results_from_gradesheet(student).result
        end
      end

      def student_grade_submitted?(student)
        if @student_grade_hash[student.id]
          @student_grade_hash[student.id].submitted?
        else
          student_results_from_gradesheet(student).submitted?
        end
      end

      def average
        total = 0
        count = 0
        gradesheet.each do |student_result|
          next unless student_result.submitted?

          count += 1
          total += student_result.formatted_submitted_not_due_score
        end

        count.positive? ? total / count : 0
      end

      private def student_results_from_gradesheet(student)
        result = nil
        gradesheet.each do |student_result|
          next unless student.id == student_result.user_id

          result = OpenStruct.new(
            submitted?: student_result&.submitted?,
            result: student_result&.formatted_submitted_not_due_score || 0
          )
          break
        end
        # Return something that quacks correctly even if student is not found in gradesheet.
        @student_grade_hash[student.id] = result || OpenStruct.new(submitted?: false, result: 0)
      end

      private def gradesheet
        @gradesheet ||=
          GradebookEngine::GradebookAPI.find_section_assignment_grades(
            section_id: @section.id,
            activity_id: @activity.id,
            additional_dimensions: additional_dimensions
          )
      end

      private def additional_dimensions
        { exclude_sample_student: true }
      end
    end
  end
end
