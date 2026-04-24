module StandardsReports
  module ProgressMonitoring
    # NOTE: This replaces SectionReportRow for getting report based on
    # groups of assessments.
    class ByGroupSectionReportRow < ByGroupReportRowBase
      attr_accessor :data_set, :guids, :standard
      alias header standard

      def initialize(standard:, guid: nil, record: nil, activities: [], grouped_activity_ids: {})
        super
      end
    end
  end
end
