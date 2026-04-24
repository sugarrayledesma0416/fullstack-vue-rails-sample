class AddClientIdToLtiContextLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :lti_context_links, :client_id, :string
  end
end
