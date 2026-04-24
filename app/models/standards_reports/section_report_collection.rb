module StandardsReports
  class SectionReportCollection < ReportCollectionBase
    attr_accessor :direction, :sort, :standard_sets, :standard

    def initialize(activities:, section:, standard_sets:, direction: nil, sort: nil, standard: nil)
      self.activities = activities
      self.section = section
      self.standard_sets = standard_sets
      self.standard = standard
      self.sort = sort
      self.direction = direction
      super()
    end

    private def default_sort
      sort_by_standard('asc')
    end

    private def secondary_sort_method
      :standard
    end

    private def init_report_rows
      standards.each do |standard|
        rows << StandardsReports::SectionReportRow.new(standard:, activities:)
      end
    end

    private def add_row(record)
      guids = record.results_data.keys
      guids.each do |guid|
        standards = standards_for_guid(guid)
        standards.each do |standard|
          find_or_create_row(standard, guid, record)
        end
      end
    end

    def find_or_create_row(standard, guid, record)
      existing_row = rows.detect do |row|
        row.standard == standard
      end

      if existing_row
        existing_row.add_data(record, guid)
      else
        rows << StandardsReports::SectionReportRow.new(
          standard:,
          guid:,
          record:,
          activities:
        )
      end
    end

    def standards_for_guid(guid)
      standards.select do |standard_obj|
        standard_obj.guids.include?(guid)
      end
    end

    private def standards
      return @standards if defined?(@standards)

      # will contain guids from multiple standards
      vendor_guids = alignments.map(&:vendor_standard_guid).uniq

      # retrieve the related standards, filtered by vendor_guids
      @standards = Standard.where(vendor_standard_set_guid: standard_sets.pluck(:vendor_guid))
                           .where(vendor_guid: vendor_guids).map do |standard_obj|
        next if standard && (standard.id.to_i != standard_obj.id) ||
          !standard_obj.match_grade_levels?(section.course.program)
        
        StandardInfo.new(
          label: standard_label(standard_obj),
          description: standard_obj.description,
          guids: alignment_question_guids(standard_obj.vendor_guid),
          id: standard_obj.id,
          vendor_guid: standard_obj.vendor_guid
        )
      end.compact
    end
  end
end
