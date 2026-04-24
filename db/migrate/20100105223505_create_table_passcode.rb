class CreateTablePasscode < ActiveRecord::Migration[4.2]
  def self.up
    create_table :passcodes do |t|
      t.string    :passcode
      t.string    :access_type
      t.string    :distribution_method
      t.text      :comment
      t.datetime  :generated_at
      t.integer   :generated_by
      t.timestamps
    end
  end

  def self.down
    drop_table :passcodes
  end
end
