class CreateTableVocabProgramGroups < ActiveRecord::Migration[4.2]
  def self.up
    create_table :vocab_program_groups do |t|
      t.timestamps
    end
  end

  def self.down
    drop_table :vocab_program_groups
  end
end
