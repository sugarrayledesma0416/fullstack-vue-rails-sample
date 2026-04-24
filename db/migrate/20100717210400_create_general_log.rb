class CreateGeneralLog < ActiveRecord::Migration[4.2]
  def self.up
    create_table :general_logs do |t|
      t.string  :log_type
      t.string  :data_format
      t.text    :data
      t.timestamps
    end    
  end

  def self.down
    drop_table :general_logs
  end
end
