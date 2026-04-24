class AddSearchableToStandards < ActiveRecord::Migration[6.1]
  def change
    add_column :standards, :searchable, :boolean, default: true
  end
end
