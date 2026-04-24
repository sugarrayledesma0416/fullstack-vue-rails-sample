class AddUniqueIndexToOneRosterLinkedUsers < ActiveRecord::Migration[5.2]
  def change
    remove_index :one_roster_linked_users, %i[school_id external_username]
    add_index :one_roster_linked_users,
              %i[school_id external_username],
              name: :idx_one_roster_linked_users_school_username,
              unique: true
  end
end
