class GroupChatRecording < ApplicationRecord
  self.ignored_columns = %w[partner_practice]

  belongs_to :user
  belongs_to :activity
  serialize :participants, JSON
  serialize :practicing_users, JSON

  after_initialize do
    # Need to set the default value for practicing_users this way,
    # setting the default in the migration generates an error in ActiveRecord.
    # setting the default in the serialize line also generates an error.
    self.practicing_users = [] if new_record? && practicing_users.nil?
  end

  def partner_users
    @partner_users ||= User.where(id: participants).index_by(&:id)
  end
end
