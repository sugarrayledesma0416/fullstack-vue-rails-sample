class GroupChatPresenter < PartnerChatPresenter
  def original_partner(student)
    @users_and_partners[student.id].partner_users[student.id]
  end

  private def build_users_and_partners(partner_chat_recordings)
    # This method builds a hash that maps user ids to group chat recordings.
    # We use this to know which user made the recording and which are the partners.
    return {} if partner_chat_recordings.empty?

    user_ids = partner_chat_recordings.map(&:user_id).uniq
    users_by_id = User.where(id: user_ids).index_by(&:id)

    partner_chat_recordings.each do |recording|
      recording.association(:user).target = users_by_id[recording.user_id]
    end

    partner_chat_recordings.each_with_object({}) do |recording, result|
      result[recording.user.id] = recording
      recording.participants.each do |partner_id|
        result[partner_id.to_i] = recording unless recording.practicing_users.include? partner_id
      end
    end
  end

  def partner_is_practicing?(student, user_who_submitted)
    unless (student == user_who_submitted)
      return @users_and_partners[user_who_submitted.id].practicing_users.include? student.id.to_s
    end
    false
  end
end
