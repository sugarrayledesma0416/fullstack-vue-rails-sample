class AddIsArchivedToSections < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :is_archived, :boolean , :default => false

    Section.all.each do |t|
      t.update_attribute :is_archived, false
    end
  end

  def self.down
    remove_column :sections , :is_archived
    end
end
