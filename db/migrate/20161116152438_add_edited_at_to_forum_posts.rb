class AddEditedAtToForumPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :forum_posts, :edited_at, :datetime
  end
end
