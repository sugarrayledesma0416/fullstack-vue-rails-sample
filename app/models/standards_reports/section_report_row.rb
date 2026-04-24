module StandardsReports
  class SectionReportRow < ReportRowBase
    attr_accessor :data_set, :guids, :standard
    alias :header :standard

    def initialize(standard:, guid: nil, record: nil, activities: [])
      super
    end
  end
end
