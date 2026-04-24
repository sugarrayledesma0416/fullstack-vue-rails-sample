class CreateAssignmentRelatedTables < ActiveRecord::Migration[4.2]
  def self.up
    create_table :assignments do |t|
      t.integer :activity_id
      t.date    :due_date
      t.integer :study_plan_id 

      t.timestamps
    end

    create_table :banks do |t|
      t.integer :program_id
      t.integer :unit_id
      t.integer :rank
      t.string  :name
    end

    create_table :activities do |t|
      t.string  :title
      t.integer :bank_id
      t.integer :bank_rank
    end
  end

  def self.down
    drop_table :assignments
    drop_table :banks
    drop_table :activities
  end
end
