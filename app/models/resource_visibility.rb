module ResourceVisibility
  private def student_resource_viewable?(resource, setting, current_user)
    if current_user.is_resource_editor? || (current_user.instructor? && setting.nil?)
      resource.vhl_student_resource?
    else
      setting&.shown?
    end
  end
end
