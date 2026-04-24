module StandardsReports
  class StudentDetailReportCollection < ReportCollectionBase
    attr_accessor :direction, :sort, :standard, :standard_sets

    def initialize(activities:, section:, standard:, standard_sets:, direction: nil, sort: nil)
      self.activities = activities
      self.section = section
      self.standard_sets = standard_sets
      self.standard = standard
      self.sort = sort
      self.direction = direction
      super()
    end

    def init_report_rows
      students.each do |student|
        rows << StandardsReports::StudentDetailReportRow.new(
          activities:,
          standard: report_standard,
          student:
        )
      end
    end

    private def default_sort
      sort_by_student('asc')
    end

    private def secondary_sort_method
      :student
    end

    private def sort_by_student(dir)
      sort_direction(rows.sort_by(&:student), dir)
    end

    private def add_row(record)
      guids = record.results_data.keys
      guids.each do |guid|
        next unless report_standard.guids.include?(guid)

        student = students.detect { |st| st.user_id == record.user_id }
        find_or_create_row(student, guid, record) if student
      end
    end

    def find_or_create_row(student, guid, record)
      existing_row = rows.detect do |row|
        row.student == student
      end

      if existing_row
        existing_row.add_data(record, guid)
      else
        rows << StandardsReports::StudentDetailReportRow.new(
          activities:,
          guid:,
          record:,
          standard:,
          student:
        )
      end
    end

    private def report_standard
      return @report_standard if defined?(@report_standard)

      @report_standard = StandardInfo.new(
        label: standard_label(standard),
        description: standard.description,
        guids: alignment_question_guids(standard.vendor_guid),
        id: standard.id,
        vendor_guid: standard.vendor_guid
      )
    end
  end
end
