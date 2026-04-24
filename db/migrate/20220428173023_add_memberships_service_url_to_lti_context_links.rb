class AddMembershipsServiceUrlToLtiContextLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :lti_context_links, :memberships_service_url, :string
  end
end
