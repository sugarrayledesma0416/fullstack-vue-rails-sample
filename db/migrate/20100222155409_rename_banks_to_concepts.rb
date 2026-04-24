class RenameBanksToConcepts < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :activities, :bank_rank
    rename_column :activities, :bank_id, :concept_id
    rename_table :banks, :concepts
  end

  def self.down
    add_column :activities, :bank_rank, :integer
    rename_column :activities, :concept_id, :bank_id
    rename_table :concepts, :banks
  end
end
