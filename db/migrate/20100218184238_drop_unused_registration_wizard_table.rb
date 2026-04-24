class DropUnusedRegistrationWizardTable < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :wizard_state_registrations
  end

  def self.down
    create_table :wizard_state_registrations do |t|
      t.string :aasm_state
      
      t.timestamps
    end
  end
end
