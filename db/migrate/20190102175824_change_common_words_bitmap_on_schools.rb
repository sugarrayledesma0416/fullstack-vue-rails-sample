class ChangeCommonWordsBitmapOnSchools < ActiveRecord::Migration[4.2]
  def change
    change_column :schools, :common_words_bitmap,  :bigint
  end
end
