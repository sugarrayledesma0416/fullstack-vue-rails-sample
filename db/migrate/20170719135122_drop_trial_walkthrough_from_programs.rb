class DropTrialWalkthroughFromPrograms < ActiveRecord::Migration[4.2]
  def change
    remove_column :programs, :trial_walkthrough
  end
end
