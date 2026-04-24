class DropPersonalizedProgramsTable < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :personalized_programs
  end

  def self.down
    create_table :personalized_programs do |t|
      t.integer :user_id
      t.integer :program_id
    end
  end
end
