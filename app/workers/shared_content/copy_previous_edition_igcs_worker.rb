module SharedContent
  class CopyPreviousEditionIgcsWorker
    include Sidekiq::Worker

    def perform(previous_program_id, program_id, instructor_id, activities_to_copy_ids)
      previous_program = Program.find(previous_program_id)
      program = Program.find(program_id)
      instructor = Instructor.find(instructor_id)
      activities_to_copy = InstructorCreatedActivity.where(id: activities_to_copy_ids)

      copier = ProgramPreviousEditionIgcCopier.new(
        previous_program,
        program,
        instructor,
        activities_to_copy
      )

      copier.copy_previous_edition_igcs
    rescue StandardError => e
      Sidekiq.logger.error("Failed to copy editions: #{e.message}")
      Sidekiq.logger.error(e.backtrace.join("\n"))
    end
  end
end
