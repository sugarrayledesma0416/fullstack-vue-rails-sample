class AddTrialWalkthroughToPrograms < ActiveRecord::Migration[4.2]
  def change
    add_column :programs, :trial_walkthrough, :string
  end
end
