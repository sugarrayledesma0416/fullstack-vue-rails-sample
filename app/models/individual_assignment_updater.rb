class IndividualAssignmentUpdater
  attr_accessor :params, :section_id

  def initialize(params, section_id)
    self.params = params
    self.section_id = section_id
  end

  def update
    users_by_activity.each do |activity_id, user_data|
      # Do one transaction per activity to minimize table locking.
      IndividualAssignment.transaction do
        # Start by resetting the assignment status for all users for
        # the given activity.
        destroy_existing_assignments(activity_id)
        # Add (or re-add) individual assignments for the users who are
        # supposed to be assigned.
        create_new_assignments(activity_id, user_data)
      end
    end
  end

  # Params are a nested hash with
  # - activities at the top level,
  # - user ids as the next level, and the value 1 or 0 depending on whether
  # the activity is assigned to that particular user. e.g.:
  # {
  #   'activity_123' => { 'user_234' => 0, 'user_345' => 1 },
  #   'activity_456' => { 'user_234' => 1,'user_345' => 0  }
  # }
  # Returns a hash with activity ids as keys and an array of users to
  # whom the activity should be assigned:
  # { 123 => [345], 456 => [234] }
  private def users_by_activity
    params.each_with_object({}) do |(activity_key, users), memo|
      next unless activity_key.start_with?('activity_')

      activity_id = activity_key.gsub('activity_', '').to_i
      memo[activity_id] = extract_user_data(users)
    end
  end

  # Return an array of [user_id, due_date] arrays extracted from the keys of the params
  # prefixed by user_ and their associated hashes, but only if the "assigned" value in the
  # associated hash is 1.
  private def extract_user_data(users)
    users.map do |user_key, value|
      next if value['assigned'].to_i != 1

      [
        user_key.gsub('user_', '').to_i,
        value['due_date']
      ]
    end.compact
  end

  private def destroy_existing_assignments(activity_id)
    IndividualAssignment.where(
      activity_id: activity_id, section_id: section_id
    ).destroy_all
  end

  private def create_new_assignments(activity_id, user_data)
    user_data.each do |user_id, due_date|
      IndividualAssignment.create!(
        activity_id: activity_id, section_id: section_id, user_id: user_id, due_date: due_date
      )
    end
  end
end
