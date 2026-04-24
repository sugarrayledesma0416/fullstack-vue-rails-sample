class AddReleasedToUnits < ActiveRecord::Migration[4.2]
  
  # ensure class exists so we can update records
  class Unit < ActiveRecord::Base
  end

  def self.up
    add_column :units, :released, :boolean, :null => false, :default => false

    # mark released any units for books that were already fully released before this code was
    # first deployed.  this excludes 2014 copyright titles
    Unit.where('program_id < 50').update_all(released: true)
  end

  def self.down
    remove_column :units, :released
  end
end
