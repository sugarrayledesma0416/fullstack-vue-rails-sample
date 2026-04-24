class UserReadingsGenerator
  attr_accessor :activity, :results, :user, :section

  def initialize(activity, results, section, user)
    self.activity = activity
    self.results = results
    self.section = section
    self.user = user
  end

  def generate
    return unless user_readings_needed?

    generate_user_readings
    dispatch_notification
  end

  private def generate_user_readings
    user_readings_attributes.each do |user_reading_attributes|
      UserReading.create!(user_reading_attributes)
    end
  end

  private def dispatch_notification
    activity.notifications
            .dispatch('StudyPlanCreated', { section: section, user: user })
  end

  private def user_readings_needed?
    activity.has_study_plan? && user_needs_readings_for_activity?
  end

  private def user_needs_readings_for_activity?
    !UserReading.where(
      user_id: user.id,
      study_plan_concept_recommendation_id: recommendation_ids).exists?
  end

  private def user_readings_attributes
    decorated_concepts.each_with_object([]) do |concept, readings_attributes|
      concept.recommendations.each do |recommendation|
        readings_attributes << concept.attributes.merge(
          user_id: user.id,
          study_plan_concept_recommendation_id: recommendation.id)
      end
    end
  end

  private def concepts
    @concepts ||= StudyPlanConcept.includes(:recommendations)
                                  .where(
                                    activity_id: activity.id,
                                    cms_revision_id: activity.cms_revision_id,
                                    program_id: activity.program.id
                                  )
  end

  private def decorated_concepts
    @decorated_concepts ||= decorate_concepts
  end

  private def decorate_concepts
    concepts.map do |concept|
      DecoratedConcept.new(
        concept,
        results.concept_percent(concept.reference_id),
        !activity.diagnostic_v2?
      )
    end
  end

  private def recommendation_ids
    concepts.flat_map(&:recommendations).map(&:id)
  end

  class DecoratedConcept
    attr_accessor :concept, :score
    attr_writer :use_threshold

    delegate :recommendations, to: :concept

    def initialize(concept, score, use_threshold = true)
      self.concept = concept
      self.score = score
      self.use_threshold = use_threshold
    end

    def attributes
      @attributes ||= attributes_hash
    end

    private def attributes_hash
      {
        concept_score: score,
        viewed: @use_threshold ? score >= concept.threshold : false
      }
    end
  end
end
