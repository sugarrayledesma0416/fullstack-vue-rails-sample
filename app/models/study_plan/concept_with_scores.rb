module StudyPlan
  class ConceptWithScores
    attr_accessor :concept, :params

    delegate :reference_id,
             :title,
             :program_id,
             :sorted_recommendations,
             :supplemental_recommendations,
             :threshold,
             :diagnostic_concept,
             to: :concept

    delegate :type, to: :diagnostic_concept, prefix: true, allow_nil: true

    def initialize(concept, params, formative_activities = [], formative_activities_amount)
      self.concept = concept
      self.params = params
      @formative_activities = formative_activities
      @formative_activities_amount = formative_activities_amount
    end

    def readings
      @readings ||= sorted_recommendations.map do |recommendation|
        Reading.new(recommendation, params)
      end
    end

    def review_readings
      @review_readings ||= review_recommendations.map do |recommendation|
        Reading.new(recommendation, params)
      end
    end

    private def review_recommendations
      sorted_recommendations - supplemental_recommendations
    end

    def supplemental_readings
      @supplemental_readings ||= supplemental_recommendations.map do |recommendation|
        Reading.new(recommendation, params)
      end
    end

    def formative_activity_scores(by_single_concept = false)
      # When one concept does not match with any formative_activities
      # then formative_activity_scores return an array empty, for this reason
      # if formative_activities is empty we return an array with the scores
      # missed to do not lost data between column in the test prep table.
      formative_activity_scores_by_default = ['N/A'] * (
        by_single_concept ? @formative_activities.size : @formative_activities_amount
      )

      @formative_activities.each_with_index do |activity, index|
        if activity.concept_reference_ids.include?(reference_id)
          formative_activity_scores_by_default[index] = activity.concept_score(self)
        end
      end
      @formative_activity_scores ||= formative_activity_scores_by_default
    end

    def score
      @score ||= readings.first&.concept_score
    end

    def score_difference
      formative_score_available? ? (score - formative_score) : 'N/A'
    end

    def needs_reading?
      score <= threshold
    end

    def complete?
      readings.all?(&:viewed?)
    end

    private def formative_score
      if formative_score_available?
        formative_score_for_concept.to_i
      else
        'N/A'
      end
    end

    private def formative_score_for_concept
      formative_activity_scores.reject{ |s| s == 'N/A' }.first
    end

    private def formative_score_available?
      formative_score_for_concept.present?
    end
  end
end
