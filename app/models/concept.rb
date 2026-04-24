class Concept < ApplicationRecord
  include Etl

  belongs_to :lesson
  belongs_to :media_item, optional: true
  belongs_to :program
  belongs_to :program_to_program_mapping, optional: true

  has_many :activities, -> { order('activities.concept_rank') }
  has_many :track_groups
  has_many :question_bank_topics_concepts, dependent: :destroy
  has_many :question_bank_topics, through: :question_bank_topics_concepts, source: :question_bank_topic

  has_one :source_ptp_mapping, class_name: 'Concept', foreign_key: 'src_strand_id'
  has_one :destination_ptp_mapping, class_name: 'Concept', foreign_key: 'dest_strand_id'
  has_one :source_ptp_mapping, class_name: 'Concept', foreign_key: 'src_strand_id'
  has_one :destination_ptp_mapping, class_name: 'Concept', foreign_key: 'dest_strand_id'

  after_commit :update_gradebook
  delegate :display_name, to: :lesson, prefix: true

  # This method is probably not being used.
  def activities(sections: nil, current_user: nil)
    Activity.where(
      id: Services::TocActivityList.all_for_concept(self, sections:, current_user:)
    ).order('activities.concept_rank')
  end

  def label
    "#{lesson.display_name}: #{name}".html_safe
  end

  def base_name
    # Although we're stripping out white spaces on cms, there could
    # exist concepts in M3 with extraneous white spaces at the end, making
    # things like assignment wizard to fail, so we need to strip the base name
    # here as well
    base = read_attribute(:base_name)
    (base.present? ? base : name).strip
  end

  def concept_combined_rank
    (lesson_combined_rank * 100) + rank
  end
end
