class StudyPlanConceptsPresenter
  ReadingLink = Struct.new(:activity, :text)

  attr_accessor :program_id, :user_id

  def initialize(program_id, user_id)
    self.program_id = program_id
    self.user_id = user_id
  end

  def readings
    activities.map do |activity|
      ReadingLink.new(activity, link_text(activity))
    end
  end

  private def link_text(activity)
    "#{activity.lesson.display_name} - Study plan"
  end

  private def activities
    user_reading_concepts.map(&:activity)
  end

  private def user_reading_concepts
    StudyPlanConcept.select('DISTINCT study_plan_concepts.activity_id')
      .joins(:recommendations)
      .joins('INNER JOIN user_readings ON '\
        'user_readings.study_plan_concept_recommendation_id = '\
        'study_plan_concept_recommendations.id')
      .where(program_id: program_id)
      .where(user_readings: { user_id: user_id })
  end
end
