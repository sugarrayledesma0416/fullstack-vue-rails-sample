class RemoveStudySchedule < ActiveRecord::Migration[4.2]

  # Keep these so the migrations run properly, even
  # when we've removed the association in the codebase.
  class ::Assignment < ApplicationRecord
    belongs_to :study_schedule
  end

  class ::Section < ApplicationRecord
    has_one :study_schedule
  end

  class ::StudySchedule < ApplicationRecord
    belongs_to :section
  end

  def self.up
    add_column :assignments, :section_id, :integer
    add_index :assignments, :section_id, :name => 'assignment_section'
    ::Assignment.all.each do |assignment|
      assignment.section_id = assignment.study_schedule.section.try(:id)
      assignment.save
    end
    add_index :assignments, [:section_id, :assignable_type, :assignable_id], :unique => true, :name => 'section_assignment_uniqueness'
    remove_column :courses, :self_study
  end

  def self.down
    add_column :courses, :self_study, :integer, :limit => 1, :default => 0, :null => false
    remove_index :assignments, :name => 'section_assignment_uniqueness'
    remove_index :assignments, :name => 'assignment_section'
    remove_column :assignments, :section_id
  end
end
