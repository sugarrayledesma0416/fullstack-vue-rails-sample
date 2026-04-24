class AddConceptRankToActivity < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :concept_rank, :integer
    rename_column :activities, :rank, :toc_location_rank
    update_query = "UPDATE activities SET concept_rank = toc_location_rank"
    ActiveRecord::Base.connection.execute(update_query)
  end

  def self.down
    remove_column :activities, :concept_rank
    rename_column :activities, :toc_location_rank, :rank
  end
end
