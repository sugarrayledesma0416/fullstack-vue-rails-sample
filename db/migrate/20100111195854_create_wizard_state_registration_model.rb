class CreateWizardStateRegistrationModel < ActiveRecord::Migration[4.2]
  def self.up
    create_table :wizard_state_registrations do |t|
      t.string :aasm_state
      
      t.timestamps
    end
  end

  def self.down
    drop_table :wizard_state_registrations
  end
end
