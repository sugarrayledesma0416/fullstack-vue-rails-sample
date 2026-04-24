module StandardsReports
  class StudentDetailReportRow < ReportRowBase
    attr_accessor :student
    alias header student

    def initialize(standard:, student:, guid: nil, record: nil, activities: [])
      super
    end
  end
end
