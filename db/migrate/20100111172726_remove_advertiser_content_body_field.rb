class RemoveAdvertiserContentBodyField < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :advertiser_contents, :body
  end

  def self.down
    add_column :advertiser_contents, :body, :text
  end
end
