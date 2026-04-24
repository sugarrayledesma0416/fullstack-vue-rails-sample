class StudentUnitBreakdownReportPresenter
  include ProficiencyAssessmentSupport
  attr_reader :collection

  def initialize(student:, section:, standard_sets:, unit:)
    @unit = unit
    @section = section
    @student = student
    @standard_sets = standard_sets
  end

  # this will provide the info needed to fill out the
  # first portion of the unit breakdown report that
  # shows # of standards in each range,
  # returns a hash, keyed by range name with the count of
  # mapped standards for that range as the value
  # e.g {"meeting"=>12, "progressing"=>1, "needs some support"=>2,
  #      "needs moderate support"=>1, "needs high support"=>5}
  def range_breakdown_standards_counts
    range_counts = {}
    range_counts[:total_standards_assessed] = standards_summary.count
    range_counts[:meeting] = standards_in_range(90, 100).count
    range_counts[:progressing] = standards_in_range(80, 89).count
    range_counts[:needs_some_support] = standards_in_range(70, 79).count
    range_counts[:needs_moderate_support] = standards_in_range(60, 69).count
    range_counts[:needs_high_support] = standards_in_range(0, 59).count
    range_counts
  end

  # this will provide the info needed to fill out the
  # second portion of the unit breakdown report that
  # shows list of standards, percent_correct for each,
  # and # of items mapped to that standard for a
  # specified range
  # NOTE: percent_correct for each standard is now calculated as:
  #  total points_earned for all items / total points_possible for all items
  # returns a hash of hashes that look like this:
  # { standard , percent_correct, items_count, total_percent_correct }
  # the key for each is the standard's vendor guid.
  # e.g.
  # {"80CF6BE0-7440-11DF-93FA-01FD9CFF4B22"=>
  # {:label=>"CCSS.ELA-Literacy.L.7.1",
  #  :percent_correct=>95.0,
  #  :items_count=>5,
  #  :total_points_possible=>22 ,
  #  :total_points_earned=>21
  #  :assessment_item_guids=>["ad3c1e29-447c-47cf-b89a-fa3d13488b88",
  #                           "aa0b6a1c-206f-4192-932e-c980dcea572e", ...]},
  # "80D60194-7440-11DF-93FA-01FD9CFF4B22"=>
  # {:label=>"A fake description with mor...",
  #  :percent_correct=>100,
  #  :items_count=>6,
  #  :total_points_possible=>6 ,
  #  :total_points_earned=>6,
  #  :assessment_item_guids=>["12ac65d6-ac41-4f79-8309-a10888712e3f",....]}}
  # NOTE: total_points_possible and total_points_earned can be ignored, they are gathered
  #       in order to calculate percent_correct for all the mapped items in the range
  # NOTE: array of assessment_item_guids now included for each standard
  def range_breakdown_results(lower, upper)
    standards_in_range(lower, upper)
  end

  # this will provide the info needed to fill out the
  # third portion of the unit breakdown report that
  # shows a single standard, its description and the breakdown of
  # percent_correct and number of items mapped to that standard per
  # proficiency assessment in the unit
  # returns a hash of hashes that look like this:
  # { percent_correct, items_count, assessment_item_guids (array), total_percent_correct }
  # the key for each is the activity id of the proficiency assessment
  # e.g.
  # { 835537=>{:percent_correct=>0.0, :items_count=>1,
  #             :assessment_item_guids=>["69d489ed-95fd-4411-a949-f6785c95be49"], :total_percent_correct=>0.0},
  #   835536=>{:percent_correct=>100.0, :items_count=>4,
  #            :assessment_item_guids=>["8e4b78f3-a05d-4e43-ac6f-b1c2dcb7f11e",
  #                                     "5f531235-490b-457b-9369-d7e09ca2b190",
  #                                     "acec2b30-ccec-445e-b8d9-54460309df00",
  #                                     "9a26e3fd-2b26-41f4-94e2-e6c65d01476d"],
  #            :total_percent_correct=>400.0}}
  # NOTE: total_percent_correct can be ignored, it was gathered in order to calculate
  #       percent_correct for the all the mapped items; leaving it in each hash
  #       is easier than iterating over them again to slice out only the key/value pairs
  #       needed by the caller
  def standard_unit_assessments_summary(selected_standard_vendor_guid)
    load_unit_proficiency_assessments_data
    rows = @collection.rows_for_standard(selected_standard_vendor_guid)
    summary = {}
    rows.map do |row|
      percent_correct = row.percent_correct.to_f
      key = row.activity.id
      if summary[key].present?
        assessment_summary = summary[key]
        assessment_summary[:items_count] = assessment_summary[:items_count] + 1
        # need to keep a running total so I can determine percent_correct based on all the
        # assessment items for each assessment mapped to the specified standard.
        assessment_summary[:total_percent_correct] = assessment_summary[:total_percent_correct] + percent_correct
        assessment_summary[:percent_correct] = assessment_summary[:total_percent_correct] / assessment_summary[:items_count]
        assessment_summary[:assessment_item_guids] << row.guid
      else
        summary[key] = { label: assessment_label(row.activity), percent_correct: percent_correct, items_count: 1, assessment_item_guids: [row.guid], total_percent_correct: percent_correct }
      end
    end
    summary
  end

  # these next 2 methods provide what the caller needs to display the student's results for
  # any assessment item, in the view formerly known as "assessment item modal";

  # caller knows what assessment the assessment items are from;
  # that value  is located in the return values from this call:
  # standard_unit_assessments_summary(selected_standard_vendor_guid)
  # e.g. activity.content_object gives the caller access to all the questions,
  # they can be queried by guid to get the label, points possible, and sub activity type.
  # to find a specific question given the guid do this:
  # question = assessment.content_object.questions.detect { |question| question.guid == guid }
  def assessment(assessment_id)
    Activity.find(assessment_id)
  end

  # Assumption: student has submitted an attempt for the referenced assessment
  # and it has a grade; attempt.results holds the student's responses.
  # helpful methods:
  #    results.correct?(label) e.g. in an auto-graded, did the student get it right?
  #    results.points_possible(label)
  #    results.points_earned(label)
  # Also useful when we get to instructor-graded;
  # this call will indicate a "not yet graded" instructor-graded question
  # (I am unclear as to whether or not we will we have any of those)
  # attempt.results.correctness(label) == 'pending'
  def current_student_attempt_for_assessment(assessment)
    Attempt.find_by_student_section_and_activity(@student, @section, assessment)
  end

  # find the 2-3 proficiency assessments in the unit
  # (is there a method for this? see where the multi-unit dropdown is filled);
  # create a SingleStudentDetailReport for each
  private def load_unit_proficiency_assessments_data
    prof_assessments = proficiency_assessments
    # create a SingleStudentDetailReportCollection with all
    # the proficiency assessments in the unit
    @collection = StandardsReports::SingleStudentDetailReportCollection.new(
      assessments: prof_assessments,
      section: @section,
      student: @student,
      standard_sets: @standard_sets
    )
  end

  # find the 2-3 proficiency assessments in the unit;
  # return them in an array
  private def proficiency_assessments
    assessments = @unit.lessons.map do |lesson|
      lesson.activities(sections: [@section]).order(:toc_location_rank).select(&:proficiency_assessment?)
    end
    # get rid of empty value when a lesson in the unit
    # has no proficiency assessments
    assessments.flatten
  end

  # returns a hash of hashes that look like this:
  # { standard , percent_correct, items_count, total_percent_correct }
  # the key for each is the standard's vendor guid.
  # e.g.
  # This provides the data for panels 1 and 2 of the Student Unit Breakdown Report
  # {"80CF6BE0-7440-11DF-93FA-01FD9CFF4B22"=>
  # {:label=>"CCSS.ELA-Literacy.L.7.1", :percent_correct=>98.0, :items_count=>3, :total_percent_correct=>294.0},
  # "80D60194-7440-11DF-93FA-01FD9CFF4B22"=>
  # {:label=>"A fake description with mor...",
  #  :percent_correct=>97.5,
  #  :items_count=>2,
  #  :assessment_item_guids=>["12ac65d6-ac41-4f79-8309-a10888712e3f", "e1c19962-18ea-4a5b-9675-4df13def5996"]}}
  private def standards_summary
    return @standards_summary if defined? @standards_summary

    load_unit_proficiency_assessments_data
    standards_list = collection.report_rows.map(&:standard).uniq
    # need to dedupe further as the same std mapped to assessments items in more than one assessment
    # will appear in this list as many times as the number of those assessments
    standard_vendor_guids = []
    standards_list.map do |std|
      next if standard_vendor_guids.include?(std.vendor_guid)
      standard_vendor_guids << std.vendor_guid
    end
    @standards_summary = {}
    standard_vendor_guids.each do |std_vendor_guid|
      rows = collection.rows_for_standard(std_vendor_guid)
      rows.map do |row|
        percent_correct = row.percent_correct.to_f
        points_possible = row.points_possible.to_f
        points_earned = row.points_earned.to_f
        key = row.standard.vendor_guid
        if @standards_summary[key].present?
          std_summary = @standards_summary[key]
          std_summary[:items_count] = std_summary[:items_count] + 1
          # need to keep a running total so I can determine percent_correct based on all the
          # assessment items mapped to the specified standard.
          std_summary[:total_points_possible] = std_summary[:total_points_possible] + points_possible
          std_summary[:total_points_earned] = std_summary[:total_points_earned] + points_earned
          std_summary[:percent_correct] = ((std_summary[:total_points_earned] / std_summary[:total_points_possible]) * 100).round(0)
          std_summary[:assessment_item_guids] << row.guid
        else
          @standards_summary[key] = { id: row.standard.id, label: row.standard.label, description: row.standard.description, percent_correct: percent_correct, items_count: 1, assessment_item_guids: [row.guid], total_points_possible: points_possible, total_points_earned: points_earned }
        end
      end
    end
    @standards_summary
  end

  # return the Standards and their summaries for all the
  # standards that have percent_correct
  # values that fall within the specified range.
  private def standards_in_range(lower, upper)
    result_summaries = {}
    standards_summary.map do |key, memo|
      if memo[:percent_correct].between?(lower, upper)
        result_summaries["#{key}"] = memo
      end
    end
    result_summaries
  end
end
