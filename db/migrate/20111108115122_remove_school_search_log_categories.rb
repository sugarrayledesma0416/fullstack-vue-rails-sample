class RemoveSchoolSearchLogCategories < ActiveRecord::Migration[4.2]
  def self.up
    drop_table "school_search_log_categories"
  end

  def self.down
    create_table "school_search_log_categories", :force => true do |t|
      t.string "code"
      t.string "label"
    end
  end
end
