class IndividualAssignment < ApplicationRecord
  include Etl

  after_commit :update_gradebook

  belongs_to :user
  belongs_to :section

  def gb_deletion_opts
    {
      action: 'delete',
      activity_id: activity_id,
      model_name: gradebook_class_name,
      section_id: section_id,
      user_id: user_id
    }
  end

  # overrides method in Etl module;
  # IndividualAssignments must update the Gradebook directly
  # instead of using Sidekiq to maintain the order by
  # which an IndividualAssignment is deleted and then re-added when
  # it is assigned to different students.
  def notify_update
    opts = { action: 'add_update', id: id, model_name: gradebook_class_name }
    invoke_gb_updater(opts)
  end

  # overrides method in Etl module;
  # IndividualAssignments delete from the Gradebook directly
  def notify_deletion
    invoke_gb_updater(gb_deletion_opts)
  end

  # Returns the actual due date for the individual assignment.
  # This method is added for convenience, to make it easier to write the feature
  # spec for the gradebook single-student-scores view.
  def effective_due_date
    due_date || parent_assignment.due_date
  end

  private def invoke_gb_updater(opts)
    return if Rails.env.test? && !Rails.application.config.update_test_gradebook

    "Gb#{gradebook_class_name}Migrator".classify.constantize.new(opts).update_object
  end

  private def parent_assignment
    Assignment.find_by(assignable_id: activity_id, section_id: section_id)
  end
end
