class AddDeletedToForumPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :forum_posts, :deleted, :boolean, null: false, default: false
  end
end
