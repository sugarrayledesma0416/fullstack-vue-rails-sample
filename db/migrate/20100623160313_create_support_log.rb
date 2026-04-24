class CreateSupportLog < ActiveRecord::Migration[4.2]
  def self.up
    create_table :support_logs do |t|
      t.integer     :created_by
      t.integer     :user_id
      t.integer     :months_extended
      t.text        :privileges
      t.text        :comment
      t.timestamps
    end
  end

  def self.down
    drop_table :support_logs
  end
end
