class CreateScoreAdjustments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :score_adjustments do |table|
      table.integer  :section_id
      table.integer  :student_id
      table.integer  :score_id
      table.string   :action
      table.integer  :old_value
      table.integer  :new_value
      table.text     :comment

      table.timestamps
    end
  end

  def self.down
    drop_table :score_adjustments  
  end
end
