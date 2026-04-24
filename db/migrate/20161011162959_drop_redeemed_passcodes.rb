class DropRedeemedPasscodes < ActiveRecord::Migration[4.2]
  def change
    drop_table :redeemed_passcodes
  end
end
