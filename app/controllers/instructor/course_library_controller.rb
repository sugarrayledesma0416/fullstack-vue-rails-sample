class Instructor::CourseLibraryController < RequireInstructorController

  def hide
    CourseLibraryActivity.hide_activity(params[:activity_id], current_section.course_id)
    response_json = {:success => true}
    render :json => response_json
  end

  def unhide
    CourseLibraryActivity.unhide_activity(params[:activity_id], current_section.course_id)
    render :json => {:success => true}
  end

  def activity_is_assigned?(activity_id)
    activity = Activity.find(activity_id)
    Assignment.by_activities_and_sections(activity, current_section).exists?
  end
  private :activity_is_assigned?

end
