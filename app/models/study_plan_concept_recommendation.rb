class StudyPlanConceptRecommendation < ApplicationRecord
  TYPES = %w[reference supplemental vocabulary].freeze

  belongs_to :study_plan_concept
  has_one :activity, through: :study_plan_concept
  has_many   :user_readings

  scope :supplemental, -> { where(recommendation_type: 'supplemental') }

  validates :recommendation_type, inclusion: { in: TYPES }

  TYPES.each do |type|
    define_method "#{type}?" do
      recommendation_type == type
    end
  end

  def vocabulary?
     recommendation_type == 'vocabulary' || title.downcase.include?('vocabulary')
  end

  def supplemental_activity
    return unless supplemental?

    Activity.find_by_cms_activity_id_in_program(cms_activity_id, program_id)
  end

  def reference_activity
    return unless reference? || vocabulary?

    Activity.find_by_cms_activity_id_in_program(cms_activity_id, program_id)
  end

  def program_id
    activity.program&.id
  end
end
