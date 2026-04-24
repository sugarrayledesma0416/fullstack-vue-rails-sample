class AddIndicesForSorting < ActiveRecord::Migration[4.2]
  def self.up
    remove_index :activities, :toc_location
    add_index :activities, [:toc_location, :toc_location_rank], :name => 'by_location_sort_by_rank'

    remove_index :units, :rank
    remove_index :units, :program_id
    add_index :units, [:program_id, :rank], :name => 'by_program_sort_by_rank'

    remove_index :lessons, :rank
    remove_index :lessons, :unit_id
    add_index :lessons, [:unit_id, :rank], :name => 'by_unit_sort_by_rank'

    remove_index :courses, :owner_id
    add_index :courses, [:owner_id, :name, :start_date], :name => 'by_owner_sort_by_name_and_start_date'
  end

  def self.down
    remove_index :activities, :name => :by_location_sort_by_rank
    add_index :activities, :toc_location

    remove_index :lessons, :name => :by_unit_sort_by_rank
    add_index :lessons, :rank
    add_index :lessons, :unit_id

    remove_index :units, :name => :by_program_sort_by_rank
    add_index :units, :rank
    add_index  :units, :program_id

    remove_index :courses, :name => :by_owner_sort_by_name_and_start_date    
    add_index :courses, :owner_id
  end
end
