class CreateMaestro2Passcodes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :maestro2_passcodes do |t|
      t.string    :passcode, :null => false, :limit => 25  
      t.string    :passcode_for, :null => false  
      t.integer   :book_id, :null => false  
      t.integer   :redeemer_id
      t.integer   :cart_id
      t.datetime  :date_redeemed
      t.datetime  :date_purchased
      t.datetime  :date_distributed
      t.boolean   :is_instructor, :null => false  
      t.boolean   :is_deactivated, :null => false  
      t.boolean   :is_distributed
      t.boolean   :is_for_testing, :null => false  
      t.string    :distribution_method, :limit => 100 
      t.string    :lit_request_id
      t.timestamps
    end
  end

  def self.down
    drop_table :maestro2_passcodes
  end
end
