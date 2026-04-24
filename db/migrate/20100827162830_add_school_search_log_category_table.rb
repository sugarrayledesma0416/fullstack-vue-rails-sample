class AddSchoolSearchLogCategoryTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :school_search_log_categories do |t|
      t.string :code
      t.string :label
    end
    add_column :school_search_logs, :category_id, :integer, :default => 1
  end

  def self.down
    drop_table :school_search_log_categories
    remove_column :school_search_logs, :category_id
  end
end
