class ChangePrivilegesBookIdToProgramId < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :privileges, :book_id, :program_id
  end

  def self.down
    rename_column :privileges, :program_id, :book_id
  end
end
