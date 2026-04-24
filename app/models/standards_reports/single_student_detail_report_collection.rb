module StandardsReports
  class SingleStudentDetailReportCollection < ReportCollectionBase

    attr_accessor :assessments, :student, :standard_sets, :direction, :sort

    def initialize(assessments:, section:, student:, standard_sets:, direction: nil, sort: nil)
      self.assessments = assessments
      self.section = section
      self.student = student
      self.standard_sets = standard_sets
      self.sort = sort
      self.direction = direction
      prep_data
      super()
    end

    def report_rows
      return @report_rows if defined?(@report_rows)

      # This will populate self.rows
      init_report_rows

      # default sort is by percent_correct and secondary is by standard
      # we could have duplicate rows for a Standard as it could be mapped
      # to any number of assessment items in any of the assessments
      @report_rows = sort_rows
    end

    # add a row per assessment item and its mapped standard (StandardInfo record);
    # add the StandardResults for the assessment that the assessment item
    # comes from.
    def init_report_rows
      assessments.map do |assessment|
        standards(assessment).map do |std|
          standards_results_for_assessment = standards_results(assessment)
          # get all assessment item guids mapped to this standard
          # and add a row for each; each AI will only be mapped to one
          # standard in any given standard set
          mapped_item_guids = alignment_question_guids(assessment, std.vendor_guid)
          mapped_item_guids.map do |item_guid|
            next if standards_results_for_assessment.nil?
            next unless standards_results_for_assessment.results_data.keys.include? item_guid

            rows << StandardsReports::SingleStudentDetailReportRow.new(
              activity: assessment,
              guid: item_guid,
              record: standards_results_for_assessment,
              standard: std
            )
          end
        end
      end
    end

    # Superclass requires an implementation, however it is
    # a NOOP. Adding the standard_results to each row
    # was done in init_report_rows;
    def add_row; end

    # return the assessmment items that have percent_correct
    # values that fall within the specified range.
    # This will give us the data we need for the initial Unit Breakdown Report
    def rows_in_range(lower, upper)
      result_rows = []
      report_rows.map do |row|
        if row.percent_correct_within_range?(lower, upper)
          result_rows << row
        end
      end
      result_rows
    end

    # return the rows for assessment_items that are mapped to the specified standard
    # TODO: this will probably need to work with multiple standards
    def rows_for_standard(standard_vendor_guid)
      result_rows = []
      report_rows.map do |row|
        if row.standard.vendor_guid == standard_vendor_guid
          result_rows << row
        end
      end
      result_rows
    end

    # for each assessment, it loads the alignments, standards_results
    # and mapped standards
    private def prep_data
      @alignments_by_assessment = {}
      @standards_results_by_assessment = {}
      assessments.pluck(:cms_activity_id).each do |cms_activity_id|
        @alignments_by_assessment[cms_activity_id] =
          StandardAlignment.select(:vendor_standard_guid, 'assessment_items.guid AS item_guid')
                           .joins(standard_asset: :assessment_item)
                           .where(assessment_items: {assessment_id: cms_activity_id})
        @standards_results_by_assessment[cms_activity_id] =
          StandardsResults.where(section_id: section,
                                 cms_activity_id:,
                                 user_id: student.id).first
      end

      load_standards_by_assessment
    end

    # This is somewhat duplicated code from ReportCollectionBase
    # whereas that class has a single alignments variable, we have
    # a hash keyed by cms_activity_id
    private def alignment_question_guids(assessment, standard_guid)
      alignments(assessment).select do |align|
        align.vendor_standard_guid == standard_guid
      end.map(&:item_guid)
    end

    #Get mapped alignments, filter out standards that do not
    # belong to the specified StandardSet; create a StandardInfo
    # instance for each and store for later use.
    private def load_standards_by_assessment
      @standards_by_assessment = {}
      assessments.map do |assessment|
        # will contain guids mapped to multiple standards
        vendor_guids = alignments(assessment).map(&:vendor_standard_guid).uniq

        # retrieve the related standards, filtered by vendor_guids
        # and within the specified standard set;
        # create a StandardInfo for each;
        # lookup standard when creating each row
        @standards_by_assessment[assessment.cms_activity_id] =
          Standard.where(vendor_standard_set_guid: standard_sets.pluck(:vendor_guid).uniq)
                  .where(vendor_guid: vendor_guids).map do |standard_obj|
            next unless standard_obj.match_grade_levels?(section.course.program)

            StandardInfo.new(
              label: standard_label(standard_obj),
              description: standard_obj.description,
              guids: alignment_question_guids(assessment, standard_obj.vendor_guid),
              id: standard_obj.id,
              vendor_guid: standard_obj.vendor_guid
            )
          end.compact
      end
    end

    private def standards(assessment)
      @standards_by_assessment[assessment.cms_activity_id]
    end

    private def alignments(assessment)
      @alignments_by_assessment[assessment.cms_activity_id]
    end

    private def standards_results(assessment)
      @standards_results_by_assessment[assessment.cms_activity_id]
    end

    private def default_sort
      sort_by_standard('asc')
    end

    private def sort_by_standard(dir)
      sort_direction(rows.sort_by { |row| [row.standard, row.percent_correct] }, dir)
    end

    private def sort_by_percent_correct(dir)
      sort_direction(rows.sort_by(&:percent_correct), dir)
    end

    private def secondary_sort_method
      sort_by_percent_correct('asc')
    end

    private def sort_by_cms_activity_id(dir)
      sort_direction(
        rows.sort_by { |r| [r.cms_activity_id, r.send(:standard)] },
        dir
      )
    end
  end
end
