module Enterprise
  class AssignActivityWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker
    include Enterprise::ValidInstructorSelector

    def perform(activity_id, instructor_id, program_id, course_id, params)
      instructor = valid_instructor(instructor_id, course_id)
      return if instructor.nil?

      activity = Activity.find(activity_id)
      program = Program.find(program_id)
      activity_assignment = ActivityAssignment.new(activity, instructor, program, { course_id: })

      action_controller_params = ActionController::Parameters.new(params)

      ActiveRecord::Base.transaction do
        activity_assignment.assign_or_update(action_controller_params)
      end
    end
  end
end
