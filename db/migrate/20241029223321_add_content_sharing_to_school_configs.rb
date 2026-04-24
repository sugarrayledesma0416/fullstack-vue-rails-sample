class AddContentSharingToSchoolConfigs < ActiveRecord::Migration[6.1]
  def change
    add_column :school_configs, :school_content_sharing, :boolean, default: true, null: false
    add_column :school_configs, :program_content_sharing_json, :json, default: {}, null: false
  end
end
