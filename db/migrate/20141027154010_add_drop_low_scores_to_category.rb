class AddDropLowScoresToCategory < ActiveRecord::Migration[4.2]
  def change
    add_column :categories, :drop_low_scores, :integer, :default => 0, :null => false
  end
end
