class InstructorActivityRemover
  attr_reader :message

  def initialize(activity)
    @activity = activity
    reset_status
  end

  def remove
    reset_status
    remove_process

    self
  end

  def successful?
    @successful
  end

  private def reset_status
    @successful = false
    @message = nil
  end

  private def remove_process
    ActiveRecord::Base.transaction do
      @activity.assignments.destroy_all
      @activity.course_library_activities.destroy_all
      @activity.custom_rubrics.destroy_all
      @activity.update!(hide_from_my_content: true)

      @successful = true
      @message = "Content successfully deleted."
    end
  rescue StandardError => e
    @message = 'Content could not be deleted.'

    VHLMonitor.notify(e)
  end
end
