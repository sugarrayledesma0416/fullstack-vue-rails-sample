module Enterprise
  class UnassignActivityWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker
    include Enterprise::ValidInstructorSelector

    def perform(activity_id, instructor_id, program_id, course_id)
      instructor = valid_instructor(instructor_id, course_id)
      return if instructor.nil?

      activity = Activity.find(activity_id)
      program = Program.find(program_id)
      activity_assignment = ActivityAssignment.new(activity, instructor, program, { course_id: })
      activity_assignment.unassign
    end
  end
end
