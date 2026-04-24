class CreateInservice < ActiveRecord::Migration[4.2]
  def self.up
    create_table  :inservice_sessions do |i|
      i.string    :audience, :default => 'Supersites'
      i.string    :session_type
      i.datetime  :session_date
      i.boolean   :archived, :default => false
      
      i.timestamps
    end
  end

  def self.down
    drop_table :inservice_sessions
  end
end
