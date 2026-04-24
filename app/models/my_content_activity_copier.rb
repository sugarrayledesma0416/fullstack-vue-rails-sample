class MyContentActivityCopier
  def self.copy(activity, user_id)
    if activity.assessment?
      copier = AssessmentCopier.new(activity.id, user_id)
      copier.copy
      copier.created_activity
    else
      activity.copy_to_instructor(user_id)
    end
  end
end
