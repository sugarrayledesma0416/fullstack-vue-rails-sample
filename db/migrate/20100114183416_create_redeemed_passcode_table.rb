class CreateRedeemedPasscodeTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :redeemed_passcodes do |t|
      t.integer :user_id
      t.integer :passcode_id

      t.timestamps
    end

  end

  def self.down
    drop_table :redeemed_passcodes
  end
end
