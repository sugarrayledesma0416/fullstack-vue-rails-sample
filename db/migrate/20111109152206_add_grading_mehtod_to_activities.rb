class AddGradingMehtodToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities , :grading_method, :string
  end

  def self.down
    remove_column :activities , :grading_method
  end
end
