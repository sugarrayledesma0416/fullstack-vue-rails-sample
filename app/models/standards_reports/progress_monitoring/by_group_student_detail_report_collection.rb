module StandardsReports
  module ProgressMonitoring
    class ByGroupStudentDetailReportCollection < StudentDetailReportCollection
      attr_accessor :grouped_activity_ids

      def initialize(
        activities:,
        section:,
        standard:,
        standard_sets:,
        direction: nil,
        sort: nil,
        grouped_activity_ids: {}
      )
        super(activities:, section:, standard:, standard_sets:, direction:, sort:)

        self.grouped_activity_ids = grouped_activity_ids
      end

      def init_report_rows
        students.each do |student|
          rows << StandardsReports::ProgressMonitoring::ByGroupStudentDetailReportRow.new(
            activities:,
            standard: report_standard,
            student:,
            grouped_activity_ids:
          )
        end
      end

      def find_or_create_row(student, guid, record)
        existing_row = rows.detect do |row|
          row.student == student
        end

        if existing_row
          existing_row.add_data(record, guid)
        else
          rows << build_by_group_row
        end
      end

      private def build_by_group_row
        StandardsReports::ProgressMonitoring::ByGroupStudentDetailReportRow.new(
          activities:,
          guid:,
          record:,
          standard:,
          student:,
          grouped_activity_ids:
        )
      end
    end
  end
end
