class AddCreatedUpdatedToSettings < ActiveRecord::Migration[4.2]
  def up
    add_column(:settings, :created_at, :datetime)
    add_column(:settings, :updated_at, :datetime)
  end

  def down
    remove_column(:settings, :created_at, :datetime)
    remove_column(:settings, :updated_at, :datetime)
  end
end
