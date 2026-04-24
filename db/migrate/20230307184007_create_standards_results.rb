class CreateStandardsResults < ActiveRecord::Migration[6.1]
  def change
    create_table :standards_results do |t|
      t.integer :user_id, null: false
      t.integer :section_id, null: false
      t.integer :cms_activity_id, null: false
      t.json :results_data

      t.timestamps
    end

    add_index(
      :standards_results,
      %i[section_id cms_activity_id user_id],
      name: 'activity_section_user',
      unique: true
    )
  end
end
