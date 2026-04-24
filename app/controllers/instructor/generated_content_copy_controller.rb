class Instructor::GeneratedContentCopyController < RequireInstructorController
  before_action :assign_copy_params, only: [:run]

  # If we get to this endpoint, we know copy needs to run.
  def run
    # Create a copy job if it doesn't exist yet, and run it.
    igc_copy_job.save!
    igc_copy_job.run

    # If everything copied, we notify the user.
    flash[:notice] = igc_copy_job.flash_notice
    render json: { status: :ok }
  rescue
    # If not everything copied, the copy job raises an error so
    #   that we can let the user know how much is left to copy.
    flash[:notice] = igc_copy_job.flash_notice if igc_copy_job.copied_count.positive?
    flash[:error] = igc_copy_job.flash_error
    render json: { status: :internal_server_error }
  end

  private def assign_copy_params
    @copy_params = { src_program_id: params[:src_program_id],
                     instructor_id: current_user.id,
                     dest_program_id: current_program.id }
  end

  private def src_program
    Program.find(@copy_params[:src_program_id])
  end

  private def dest_program
    Program.find(@copy_params[:dest_program_id])
  end

  private def igc_copy_job
    # Create job if it doesn't exist,
    #   then update its lists of to-be-copied + copied IDs.
    @igc_copy_job ||= IgcCopyJob.where(@copy_params).first_or_initialize.tap do |job|
      # The job's list of IDs to be copied is taken from the instructor.
      job.to_be_copied_ids = current_user.igc_ids_to_copy(src_program, dest_program)

      # If this job has not been run before, assign an empty list
      #   to copied_ids.
      job.copied_ids = [] if job.read_attribute(:copied_ids).nil?
    end
  end
end
