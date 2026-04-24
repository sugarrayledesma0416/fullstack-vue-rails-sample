module Instructor::CreatedActivityLinkParams
  private def instructor_created_activity_link_params(activity)
    {
      lesson_id: activity.lesson_id,
      toc_entry_id: activity.toc_location,
      program_id: activity.program.id,
      id: activity
    }
  end
end
