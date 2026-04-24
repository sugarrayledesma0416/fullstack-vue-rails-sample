class CreateOneRosterLinkedUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :one_roster_linked_users do |t|
      t.references :user, null: false
      t.references :school, null: false
      t.string :external_username, null: false
      t.string :sourced_id, null: false
      t.string :email
      # Dangerfield required fields
      t.string :guid
      t.integer :sync_token, limit: 8, default: 0
      t.string :request_id

      t.timestamps
    end

    add_index :one_roster_linked_users, :guid
    add_index :one_roster_linked_users,
              %i[school_id external_username],
              name: :idx_one_roster_linked_users_school_username
  end
end
