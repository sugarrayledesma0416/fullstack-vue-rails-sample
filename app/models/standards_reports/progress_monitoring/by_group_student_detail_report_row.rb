module StandardsReports
  module ProgressMonitoring
    # NOTE: This replaces StudentDetailReportRow for getting report based on
    # groups of assessments.
    class ByGroupStudentDetailReportRow < ByGroupReportRowBase
      attr_accessor :student
      alias header student

      def initialize(
        standard:,
        student:,
        guid: nil,
        record: nil,
        activities: [],
        grouped_activity_ids: {}
      )
        super
      end
    end
  end
end
