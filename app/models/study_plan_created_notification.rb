class StudyPlanCreatedNotification < Notification::BaseInternalActivityNotification
  def message
    "#{label(location_only = true)} Your study plan has been created."
  end

  def redirect_type
    activity = Activity.find(activity_id)
    activity.activity_type == 'diagnostic_v2' ? :study_plan_v2 : :study_plan
  end
end
