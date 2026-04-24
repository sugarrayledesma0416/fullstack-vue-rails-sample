class RecreateUserProgramsToIncludeId < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :user_programs

    create_table :user_programs do |t|
      t.integer :user_id
      t.integer :program_id
      t.integer :rank
      t.boolean :selected
    end
    add_index :user_programs, [:user_id, :program_id], :name => 'user_id_program_id_index' , :unique => true
  end

  def self.down
  end
end
