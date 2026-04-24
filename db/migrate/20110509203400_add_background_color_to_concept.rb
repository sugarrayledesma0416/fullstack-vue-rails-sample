class AddBackgroundColorToConcept < ActiveRecord::Migration[4.2]
  def self.up
    add_column :concepts, :background_color, :string
  end

  def self.down
    remove_column :concepts, :background_color
  end
end
