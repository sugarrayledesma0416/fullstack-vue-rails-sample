class QuestionBank < Activity
  belongs_to :question_bank_topic

  has_many :question_bank_revisions,
           dependent: :destroy,
           foreign_key: :activity_id,
           inverse_of: :activity

  after_save :increment_version
  after_save :set_denormalized_values

  # Don't propagate question bank instances to the gradebook db.
  skip_callback :commit, :after, :update_gradebook

  validates :title, presence: true

  attr_accessor :changed_by_id, :upload_filename, :uploaded_csv

  # Clear the default_scope defined in parent Activity class, which
  # excludes all QuestionBanks.
  self.default_scopes = []
  default_scope { where('activities.question_bank_revision_id IS NOT NULL') }

  # This method is only needed to provide compatibility with the activity
  # show view. A question bank can be associated with multiple concepts,
  # in different programs, but when displaying the preview, it's not
  # important which program is retrieved, so arbitrarily grabbing the
  # program associated with the first concept is adequate.
  def program
    question_bank_topic.concepts.first.program
  end

  def last_revised_at
    last_revision.updated_at
  end

  def last_upload_filename
    last_revision.upload_filename
  end

  def last_changed_by_name
    last_changed_by&.full_name || ''
  end

  def current_live_revision
    question_bank_revisions.find_by(status: 'live')
  end

  # rubocop:disable Rails/DynamicFindBy
  # false positive
  private def last_changed_by
    user_id = last_revision.changed_by_id
    user_id && User.find_by_id_including_archived(user_id)
  end
  # rubocop:enable Rails/DynamicFindBy

  private def last_revision
    @last_revision ||= question_bank_revisions.last
  end

  private def increment_version
    new_revision = question_bank_revisions.create! do |revision|
      revision.content_json = content_json
      revision.changed_by_id = changed_by_id
      revision.upload_filename = upload_filename
      revision.uploaded_csv = uploaded_csv
    end

    # rubocop:disable Rails/SkipsModelValidations
    # update head revision without triggering callbacks
    update_column(:question_bank_revision_id, new_revision.id)
    assign_new_content_instance
    # rubocop:enable Rails/SkipsModelValidations
  end
end
