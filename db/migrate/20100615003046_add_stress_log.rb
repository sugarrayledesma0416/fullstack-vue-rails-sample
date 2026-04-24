class AddStressLog < ActiveRecord::Migration[4.2]
  def self.up
    create_table :stress_logs do |t|
      t.string :log_type
      t.string :field_1 
      t.string :field_2 
      t.string :field_3 
      t.string :field_4 
      t.text   :text_field_1
      t.timestamps
    end
  end

  def self.down
    drop_table :stress_logs
  end
end
