module StudyPlan
  class FormativeActivity
    attr_accessor :content_object, :params

    delegate :id, :strand, to: :activity
    delegate :user_id, :lesson, :summative_activity, to: :params

    def initialize(content_object, params)
      self.content_object = content_object
      self.params = OpenStruct.new params
    end

    def concept_reference_ids
      activity.study_plan_concepts.map(&:reference_id).compact.uniq
    end

    def vocabulary?
      activity.study_plan_concepts.map(&:recommendations).flatten.select(&:vocabulary?).any?
    end

    def grammar?
      !vocabulary?
    end

    def concept_score(concept)
      return if latest_attempt.nil?

      Reading.new(recommendation(concept), params).concept_score
    end

    def score
      grade ? grade.formatted_submitted_not_due_score : 0
    end

    def score_formatted_for_student_study_plan
      grade ? grade.formatted_submitted_not_due_score : 'N/A'
    end

    def activity_lesson
      activity.lesson
    end

    private def grade
      GradebookEngine::GradebookAPI.find_student_grade(
        section_id: params.section_id,
        user_id: user_id,
        activity_id: id
      )
    end

    def title
      content_object.title || activity.title
    end

    # retrieve the most recently created concept for the formative activity
    # that matches the given concept's reference_id
    private def study_plan_concept(concept)
      activity
        .study_plan_concepts
        .find_by(
          reference_id: concept.reference_id,
          cms_revision_id: latest_attempt.cms_revision_id
        )
    end

    private def latest_attempt
      return @attempts.first if defined?(@attempts)

      @attempts ||= Attempt
                    .where(
                      user_id: user_id,
                      section_id: params.section_id,
                      activity_id: id
                    )
                    .order(created_at: :desc)
      @attempts.first
    end

    private def recommendation(concept)
      study_plan_concept(concept).recommendations.first
    end

    private def activity
      return @activity if defined? @activity

      attempts_left_join = ApplicationRecord.sanitize_sql(
        [
          'LEFT OUTER JOIN attempts ON attempts.activity_id = activities.id ' \
          'AND attempts.user_id = :user_id AND attempts.section_id = :section_id',
          { user_id:, section_id: params.section_id }
        ]
      )

      @activity = Activity.unscoped
                          .joins(:lesson)
                          .includes(study_plan_concepts: :recommendations)
                          .joins(attempts_left_join)
                          .where(lesson:, cms_activity_id: content_object.id)
                          .order('attempts.user_id desc, activities.id desc')
                          .first
    end
  end
end
