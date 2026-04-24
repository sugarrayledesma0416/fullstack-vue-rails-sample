module ProficiencyAssessmentSupport
  def assessment_label(activity)
    title = activity.title.downcase
    if title.include?('mid-unit')
      'Mid-Unit'
    elsif title.include?('end-of-unit')
      'End-of-Unit'
    elsif title.include?('mid-book')
      'Mid-Book'
    elsif title.include?('end-of-book')
      'End-of-Book'
    else
      activity.title
    end
  end
end