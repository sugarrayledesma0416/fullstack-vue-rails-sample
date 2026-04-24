class AddComponentLanguageToActivities < ActiveRecord::Migration[6.1]
  def change
    add_column :activities, :component_language, :string, default: 'en'
  end
end
