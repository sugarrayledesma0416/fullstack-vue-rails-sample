class AddLinkTextToHomepageContents < ActiveRecord::Migration[4.2]
  def self.up
    add_column :homepage_contents, :link_text, :string
  end

  def self.down
    remove_column :homepage_contents, :link_text
  end
end
