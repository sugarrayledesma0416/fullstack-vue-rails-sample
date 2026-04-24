class RenameBookIdToProgramIdInMaestro2Passcodes < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :maestro2_passcodes, :book_id, :program_id
  end

  def self.down
    rename_column  :maestro2_passcodes,  :program_id, :book_id
  end
end
