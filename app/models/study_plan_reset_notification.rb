class StudyPlanResetNotification < Notification::BaseInternalActivityNotification

  def message
    "#{label(location_only = true)} Your study plan has been reset."
  end
end
