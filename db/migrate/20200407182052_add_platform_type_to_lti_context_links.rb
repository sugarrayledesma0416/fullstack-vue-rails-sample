class AddPlatformTypeToLtiContextLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :lti_context_links, :platform_type, :string
  end
end
