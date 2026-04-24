class AddCommonWordsBitmapToSchools < ActiveRecord::Migration[4.2]
  def self.up
    add_column :schools, :common_words_bitmap, :integer
  end

  def self.down
    remove_column :schools, :common_words_bitmap
  end
end
