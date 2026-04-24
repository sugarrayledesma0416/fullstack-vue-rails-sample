class SetUploadedAtToCreatedAt < ActiveRecord::Migration[4.2]
  def self.up
    ActiveRecord::Base.connection.execute('UPDATE resources set uploaded_at = created_at WHERE uploaded_at IS NULL AND created_at IS NOT NULL')
  end

  def self.down
  end
end
