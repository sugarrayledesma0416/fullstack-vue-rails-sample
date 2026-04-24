module ActivityStandardsLookup
  def mapped_standards(course)
    alignments = {}
    standard_objs = []
    standards = []
    if !activity.is_a?(EReaderItem) && activity.standards_test?
      assess_items = AssessmentItem.where(assessment_id: activity.cms_activity_id)
      assess_items.each do |ai|
        standard_objs << ai.standard_asset
                       &.standards
                       &.all
                       &.includes(:standard_set)
      end
      standard_objs.flatten!
    else
      standard_objs = activity.standard_asset
                          &.standards
                          &.all
                          &.includes(:standard_set)
    end
    standard_objs.compact.map do |std|
      next unless std.match_grade_levels?(course.program)
      standards << std.as_json(include: [:standard_set])
    end

    return if standards.nil? || course.nil?

    # De-duplicate standards and sort alphabetically by standard number
    standards.uniq!&.sort_by! { |hsh| hsh['number'] }

    standards.each do |standard|
      if course.standard_sets.pluck(:display_name).include?(standard['standard_set']['display_name'])
        if alignments[standard['standard_set']['display_name']].blank?
          alignments[standard['standard_set']['display_name']] = []
        end
        alignments[standard['standard_set']['display_name']] << standard
      end
    end
    alignments.sort_by { |key, _val| key }
  end
end
