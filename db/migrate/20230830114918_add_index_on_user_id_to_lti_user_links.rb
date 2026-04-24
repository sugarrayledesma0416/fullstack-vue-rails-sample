class AddIndexOnUserIdToLtiUserLinks < ActiveRecord::Migration[6.1]
  def change
    add_index :lti_user_links, :user_id
  end
end
