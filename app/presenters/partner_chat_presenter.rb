class PartnerChatPresenter
  def initialize(partner_chat_recordings)
    @users_and_partners = build_users_and_partners(partner_chat_recordings)
  end

  def original_partner(student)
    @users_and_partners[student.id].partner
  end

  def partner_is_practicing?(student, user_who_submitted)
    (student == user_who_submitted) ? false : (@users_and_partners[user_who_submitted.id].partner_practice)
  end

  def partner_is_not_practicing?(student, user_who_submitted)
    !partner_is_practicing?(student, user_who_submitted)
  end

  def original_user(student)
    @users_and_partners[student.id].user
  end

  def sort_students(students)
    users, partners = students.partition { |student| original_user(student) == student }
    users + partners
  end

  def build_users_and_partners(partner_chat_recordings)
    # This method builds a hash that maps user ids to partner chat recordings.
    #
    # We use this to know which user to put on the left/right when displaying
    # a partner chat activity
    partner_chat_recordings.inject({}) do |result, recording|
      result[recording.user.id] = recording
      result[recording.partner.id] = recording unless recording.partner_practice
      result
    end
  end
  private :build_users_and_partners
end
