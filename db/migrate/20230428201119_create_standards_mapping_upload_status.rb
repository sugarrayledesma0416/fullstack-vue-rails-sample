class CreateStandardsMappingUploadStatus < ActiveRecord::Migration[6.1]
  def change
    create_table :standards_mapping_upload_statuses do |t|
      t.string :index_name, null:false
      t.string :upload_type, null:false
      t.boolean :successful, null: false
      t.text :upload_errors
      t.datetime :uploaded_at_date, null: false
      t.timestamps
      t.index %i[index_name successful],
        name: :idx_stds_mapping_upload_statuses_on_index_name_and_successful
    end
  end
end
