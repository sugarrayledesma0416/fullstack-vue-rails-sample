module StandardsReports
  module ProgressMonitoring
    class ByGroupSectionReportCollection < SectionReportCollection
      attr_accessor :grouped_activity_ids

      def initialize(
        activities:,
        section:,
        standard_sets:,
        direction: nil,
        sort: nil,
        standard: nil,
        grouped_activity_ids: {}
      )
        super(activities:, section:, standard_sets:, direction:, sort:, standard:)

        self.grouped_activity_ids = grouped_activity_ids
      end

      private def init_report_rows
        standards.each do |standard|
          rows << StandardsReports::ProgressMonitoring::ByGroupSectionReportRow.new(
            standard:, activities:, grouped_activity_ids:
          )
        end
      end

      private def standards
        return @standards if defined?(@standards)

        if standard
          # NOTE: we have avoided following check present in base class code because
          # its a single standard case where all filtering might have been applied already.
          #   next if standard && (standard.id.to_i != standard_obj.id) ||
          #   !standard_obj.match_grade_levels?(section.course.program)
          @standards = [build_standard_info(standard)]
        else
          super
        end
      end

      private def build_standard_info(standard_obj)
        StandardInfo.new(
          label: standard_label(standard_obj),
          description: standard_obj.description,
          guids: alignment_question_guids(standard_obj.vendor_guid),
          id: standard_obj.id,
          vendor_guid: standard_obj.vendor_guid
        )
      end

      def find_or_create_row(standard, guid, record)
        existing_row = rows.detect do |row|
          row.standard == standard
        end
        if existing_row
          existing_row.add_data(record, guid)
        else
          rows << build_by_group_row
        end
      end

      private def build_by_group_row
        StandardsReports::ProgressMonitoring::ByGroupSectionReportRow.new(
          standard:,
          guid:,
          record:,
          activities:,
          grouped_activity_ids:
        )
      end
    end
  end
end
