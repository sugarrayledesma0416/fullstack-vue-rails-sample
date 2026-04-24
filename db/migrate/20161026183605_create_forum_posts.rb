class CreateForumPosts < ActiveRecord::Migration[4.2]
  def change
    create_table :forum_posts do |table|
      table.integer :forum_id, null: false
      table.integer :user_id, null: false
      table.integer :parent_id
      table.boolean :original_post, default: false, null: false
      table.text :text

      table.timestamps
    end

    add_index :forum_posts, :forum_id, name: 'by_forum'
  end
end
