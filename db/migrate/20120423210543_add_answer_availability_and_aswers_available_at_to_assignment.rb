class AddAnswerAvailabilityAndAswersAvailableAtToAssignment < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assignments, :answer_availability, :string
    add_column :assignments, :answers_available_at, :datetime

  end

  def self.down
    remove_column :assignments, :answer_availability
    remove_column :assignments, :answers_available_at
  end
end
