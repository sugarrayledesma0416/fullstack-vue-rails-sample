class AddUniqueIndexToLtiUserLinks < ActiveRecord::Migration[5.2]
  def change
    add_index :lti_user_links,
              %i[lti_platform_id platform_user_id user_id],
              name: :idx_lti_user_links_platform_platform_user_user_id
  end
end
