class AddCdnToActivitiesTable < ActiveRecord::Migration[4.2]
  def change
    add_column :activities, :cdn, :boolean, :default => false
  end
end
