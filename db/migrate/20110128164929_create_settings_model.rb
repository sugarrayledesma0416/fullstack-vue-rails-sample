class CreateSettingsModel < ActiveRecord::Migration[4.2]
  def self.up
    create_table :settings do |setting|
      setting.integer :user_id
      setting.string :name
      setting.string :value
    end
  end

  def self.down
    drop_table :settings
  end
end
