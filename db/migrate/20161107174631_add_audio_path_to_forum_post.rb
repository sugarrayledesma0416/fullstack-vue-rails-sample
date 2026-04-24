class AddAudioPathToForumPost < ActiveRecord::Migration[4.2]
  def change
    add_column(:forum_posts, :audio_path, :string)
  end
end
