module StudyPlan
  class Reading
    include Rails.application.routes.url_helpers

    attr_accessor :recommendation, :user_id, :has_vocab_access,
                  :program_id, :section_id, :unit_id

    delegate :cms_activity_id, :title, :recommendation_type, to: :recommendation
    delegate :id, :viewed?, :concept_score, :html_class_name, to: :user_reading, allow_nil: true

    def initialize(recommendation, params)
      self.recommendation = recommendation
      self.user_id = params[:user_id]
      self.program_id = params[:program_id]
      self.section_id = params[:section_id]
      self.unit_id = params[:unit_id]
      self.has_vocab_access = params[:has_vocab_access]
    end

    def path
      if vocabulary?
        vocabulary_path
      else
        practice_activity_path
      end
    end

    def vocabulary?
      recommendation_type == 'vocabulary'
    end

    def viewable?
      !vocabulary? || (vocabulary? && has_vocab_access)
    end

    private def vocabulary_path
      vocab_tools_words_path(program_id, section_id:, unit_id: unit_id)
    end

    private def practice_activity_path
      popup_section_activity_path(
        section_id: section_id,
        id: cms_activity_id,
        program_id: program_id
      )
    end

    private def user_reading
      @user_reading ||= UserReading.find_by(
        user_id: user_id,
        study_plan_concept_recommendation_id: recommendation.id
      )
    end
  end
end
