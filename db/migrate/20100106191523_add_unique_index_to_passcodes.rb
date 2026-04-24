class AddUniqueIndexToPasscodes < ActiveRecord::Migration[4.2]
  def self.up
    add_index(:passcodes, :passcode, unique: true)
  end

  def self.down
    remove_index(:passcodes, :passcode)
  end
end
