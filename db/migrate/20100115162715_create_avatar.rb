class CreateAvatar < ActiveRecord::Migration[4.2]
  def self.up
    create_table :avatars do |t|
      t.column :parent_id,  :integer
      t.column :content_type, :string
      t.column :filename, :string    
      t.column :thumbnail, :string 
      t.column :size, :integer
      t.column :width, :integer
      t.column :height, :integer
      t.timestamps
    end

  end

  def self.down
    drop_table :avatars
  end
end
