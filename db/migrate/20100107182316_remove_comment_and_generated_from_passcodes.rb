class RemoveCommentAndGeneratedFromPasscodes < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :passcodes, :comment
    remove_column :passcodes, :generated_at
    remove_column :passcodes, :generated_by
  end

  def self.down
    add_column :passcodes, :comment, :text
    add_column :passcodes, :generated_at, :datetime
    add_column :passcodes, :generated_by, :integer
  end
end
