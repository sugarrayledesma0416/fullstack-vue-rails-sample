class QuestionBankRevision < ApplicationRecord
  belongs_to :activity, inverse_of: :question_bank_revisions, class_name: 'QuestionBank'
  has_many :question_bank_revision_logs

  before_create { self.status = 'pending' }

  def last_changed_by_name
    last_changed_by&.full_name || ''
  end

  # rubocop:disable Rails/DynamicFindBy
  # false positive
  private def last_changed_by
    user_id = changed_by_id
    user_id && User.find_by_id_including_archived(user_id)
  end
end
