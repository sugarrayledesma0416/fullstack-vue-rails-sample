class ProgramPreviousEditionIgcCopier
  attr_accessor :previous_program, :program, :instructor, :activities_to_copy,  :igc_copy_job

  def initialize(previous_program, program, instructor, activities_to_copy)
    @previous_program = previous_program
    @program = program
    @instructor = instructor
    @activities_to_copy = activities_to_copy
    @igc_copy_job = find_or_initialize_job
  end

  # We don't put the proccess into a transaction block because
  # if any activity copy fails, we want to continue copying
  def copy_previous_edition_igcs
    begin
      @igc_copy_job.to_be_copied_ids = fetch_previous_program_activities_ids
      @igc_copy_job.copied_ids = [] if @igc_copy_job.copied_ids.nil?
      @igc_copy_job.save!
      @igc_copy_job.run
    rescue => e
      message = "Error copying previous edition IGCS: #{e.message}"
      Rails.logger.error(message)
      VHLMonitor.notify(message)
    end
  end

  private def find_or_initialize_job
    IgcCopyJob.where(copy_params).first_or_initialize.tap do |job|
      job.copied_ids ||= []
    end
  end

  private def copy_params
    {
      src_program_id: @previous_program.id,
      instructor_id: @instructor.id,
      dest_program_id: @program.id
    }
  end

  private def fetch_previous_program_activities_ids
    @activities_to_copy.pluck(:id)
  end
end
