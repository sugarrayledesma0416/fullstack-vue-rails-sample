class GroupMembershipKey
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def key
    @key ||= Digest::SHA256.hexdigest(key_material)
  end

  # Using user.id ensures users enrolled in the same sections don't get
  # the same key.
  # Joining with a separator ensures that being in sections 1 and 23
  # returns different results then being in sections 1, 2, and 3
  private def key_material
    ([user.id] + section_ids.sort).join(',')
  end

  private def section_ids
    if user.instructor?
      user.section_instructors.where(is_archived: false).pluck(:section_id)
    elsif user.student?
      user.enrollments.where(state: 'enrolled').pluck(:section_id)
    else
      # A base case that will only be reached if we introduce more
      # user types.
      []
    end
  end
end
