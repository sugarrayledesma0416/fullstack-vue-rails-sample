class AddTopicToScreencast < ActiveRecord::Migration[4.2]
  def self.up
    add_column :screencasts, :topic, :string
  end

  def self.down
    remove_column :screencasts, :topic
  end
end
