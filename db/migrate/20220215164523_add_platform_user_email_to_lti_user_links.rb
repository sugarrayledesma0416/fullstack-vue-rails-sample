class AddPlatformUserEmailToLtiUserLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :lti_user_links, :platform_user_email, :string
  end
end
