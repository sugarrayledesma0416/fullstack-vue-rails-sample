class CreateReports < ActiveRecord::Migration[4.2]
  def self.up
    create_table  :reports do |t|
      t.integer   :user_id
      t.integer   :program_id
      t.string    :name
      t.boolean   :is_archived, :default => false      

      t.timestamps
    end
  end

  def self.down
    drop_table :reports
  end
end
