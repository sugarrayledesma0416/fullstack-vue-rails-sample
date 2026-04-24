module StandardsReports
  class AssessmentSupport
    attr_accessor :collections, :assessments_result

    # standard: the standard aligned with an item in an assessment
    # student: the student displayed in the student details report
    # total_number_of_items: the sum of all the items aligned to the standard for all
    #                        the assessments selected by the user
    # assessments_result: it is an array containing the percent correct, points earned
    #                     and points possible for all the assessments selected
    #                     by the user
    # total: the aggregate of all percent correct, points earned and points possible by standard
    #        for all the assessemts selected by the user
    Row = Struct.new(
      :standard,
      :student,
      :total_number_of_items,
      :assessments_result,
      :total,
      keyword_init: true
    )

    # percent_correct: numeric value displayed as a percent. Example: 80%
    # assessment_summary: array containing the points earned and points possible values.
    #                     Example: [2.0, 2]
    Result = Struct.new(
      :assessment,
      :percent_correct,
      :assessment_summary,
      keyword_init: true
    )

    Assessment = Struct.new(
      :id,
      :title,
      keyword_init: true
    )

    def initialize(collections:)
      self.collections = collections
      self.assessments_result = []
    end

    def report
      collections.each(&:report_rows)

      @report ||= if collections.size == 1
                    single_assessment_report(rows: collections.first.rows)
                  else
                    normalize_collections_rows(collections:, row_key: 'standard')
                    multiple_rows = transpose_rows(collections:)
                    multiple_assessment_report(assessment_rows: multiple_rows)
                  end
    end

    def student_report
      collections.each(&:report_rows)

      @student_report ||= if collections.size == 1
                            single_assessment_report(rows: collections.first.rows)
                          else
                            normalize_collections_rows(collections:, row_key: 'student')
                            multiple_rows = transpose_students_rows(collections:)
                            multiple_assessment_report(assessment_rows: multiple_rows)
                          end
    end

    private def single_assessment_report(rows:)
      rows.map do |row|
        Row.new(
          standard: row.standard,
          student: row.student,
          total_number_of_items: row.total_number_of_items,
          assessments_result: Result.new(
            percent_correct: row.percent_correct_by_activity(row.activities.first.cms_activity_id),
            assessment_summary: row.assessment_summary(row.activities.first.cms_activity_id)
          )
        )
      end
    end

    private def multiple_assessment_report(assessment_rows:)
      data_set = []

      assessment_rows.each do |rows|
        row_data = rows.each_with_object({ total_number_of_items: 0 }) do |data, row|
          row[:standard] ||= data&.standard
          row[:student] = data&.student
          row[:total_number_of_items] += data&.total_number_of_items || 0
          process_assessments_info(data)
        end

        row_data[:assessments_result] = assessments_result

        multiple_assessment_row = Row.new(row_data)
        multiple_assessment_row.total = total
        data_set << multiple_assessment_row

        reset_assessment_info
      end

      data_set
    end

    private def process_assessments_info(data)
      return {} if data.nil?

      data.activities.each do |activity|
        assessments_result << Result.new(
          {
            assessment: Assessment.new(id: activity.id, title: activity.title),
            percent_correct: data.percent_correct_by_activity(activity.cms_activity_id),
            assessment_summary: data.assessment_summary(activity.cms_activity_id) || []
          }
        )
      end
    end

    # total outputs the aggregation of all points earned and points possible
    # for all the assessments selected by the user
    #
    # Input:
    # assessments_result=[
    #   <struct StandardsReports::AssessmentSupport::Result percent_correct=100, assessment_summary=[2.0, 2]>,
    #   <struct StandardsReports::AssessmentSupport::Result percent_correct=75, assessment_summary=[3.0, 4]>
    # ]
    #
    # Output:
    # total=#<struct StandardsReports::AssessmentSupport::Result percent_correct=83, assessment_summary=[5.0, 6]>
    private def total
      return if assessments_result.empty?

      total_points_earned, total_points_possible = assessments_result
                                                   .map(&:assessment_summary)
                                                   .delete_if { |data| data == [] }
                                                   .transpose
                                                   .map(&:sum)

      Result.new(
        {
          percent_correct: percent_correct(
            points_earned: total_points_earned,
            points_possible: total_points_possible
          ),
          assessment_summary: [total_points_earned, total_points_possible]
        }
      )
    end

    private def reset_assessment_info
      self.assessments_result = []
    end

    private def percent_correct(points_earned:, points_possible:)
      return if points_earned.nil? || points_possible.nil?

      ((points_earned / points_possible) * 100).round(0)
    end

    # Due to the possibility to have an standard mapped to some assessments
    # but not to others it will be impossible to identify those places in the view.
    # This method fixes this problem by creating artificial rows to fill in those
    # places.
    private def normalize_collections_rows(collections:, row_key:)
      entities = send("uniq_#{row_key}s", collections:)

      collections.each do |collection|
        entities.each do |entity|
          unless collection.rows.any? { |row| row.send(row_key) == entity }
            collection.activities do |activity|
              artificial_row = create_artificial_row(entity:, activity:, row_key:)
              collection.rows << artificial_row
            end
          end
        end
      end
    end

    private def create_artificial_row(entity:, activity:, row_key:)
      artificial_row = collections.first.rows.first.dup
      artificial_row.send("#{row_key}=", entity)
      artificial_row.activity = activity
      artificial_row.data_set = []

      artificial_row
    end

    private def transpose_rows(collections:)
      standards = uniq_standards(collections:)

      collections_by_standard = group_collections_by_standard(collections:)

      standards.map do |standard|
        rows_by_standard = []
        collections_by_standard.each do |collection|
          rows_by_standard << collection[standard.id]
        end

        rows_by_standard.flatten
      end
    end

    private def uniq_standards(collections:)
      collections.flat_map(&:rows).map(&:standard).uniq(&:id)
    end

    private def group_collections_by_standard(collections:)
      collections.map do |collection|
        collection.rows.group_by { |row| row.standard.id }
      end
    end

    private def transpose_students_rows(collections:)
      students = uniq_students(collections:)

      collections_by_student = group_collections_by_student(collections:)

      students.map do |student|
        rows_by_student = []
        collections_by_student.each do |collection|
          rows_by_student << collection[student]
        end

        rows_by_student.flatten
      end
    end

    private def uniq_students(collections:)
      collections.flat_map(&:rows).map(&:student).uniq
    end

    private def group_collections_by_student(collections:)
      collections.map do |collection|
        collection.rows.group_by(&:student)
      end
    end
  end
end
