class FindActivityConceptScoresAndGrades
  extend LightService::Action

  expects :activities
  promises :section_student_scores, :section_averages, :summative_average

  executed do |context|
    context.section_student_scores = section_student_scores(context)
    student_scores = context.section_student_scores.student_rows.map(&:student_scores)

    context.section_averages = section_averages(context, student_scores)
    context.summative_average = context.section_student_scores.summative_activity_grades&.average
  end

  def self.section_student_scores(context)
    SectionAnalytics::PracticeTest::SectionStudentsAggregator.new(
      section: context.section,
      activities: context.activities,
      assignments: context.assignments
    )
  end

  def self.section_averages(context, student_scores)
    summative_concepts(context).map do |concept|
      SectionAnalytics::PracticeTest::SectionConceptAverages.new(concept, student_scores)
    end
  end

  def self.summative_concepts_count(context)
    if context.section_student_scores.summative_activity.present?
      context.section_student_scores.summative_activity.content_object.concepts.count
    else
      0
    end
  end

  def self.summative_concepts(context)
    context.section_student_scores
           .summative_concepts
           .order(reference_id: :asc)
           .limit(summative_concepts_count(context))
  end
end
