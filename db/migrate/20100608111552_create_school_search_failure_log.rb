class CreateSchoolSearchFailureLog < ActiveRecord::Migration[4.2]
  def self.up
    create_table :school_search_logs do |t|
      t.string :name 
      t.integer :user_id
      t.string :city
      t.string :state
      t.string :country
      t.string :data, :limit => 1000
      t.timestamps
    end
  end

  def self.down
    drop_table :school_search_logs
  end
end
