class AssistantRolePolicy

  def initialize(current_focus, current_user)
    @current_focus = current_focus
    @current_user = current_user
  end

  def is_assistant?
    if current_focus_has_sections?
      any_role_for?(@current_focus.sections, 'Assistant')
    end
  end

  def is_instructor?(section_id)
    any_role_for?(section_id, 'Instructor')
  end

  def is_instructor_or_co_instructor?(section_id)
    any_role_for?(section_id, ['Instructor', 'Co-instructor'])
  end

  def any_role_for?(section_ids, role)
    SectionInstructor.where(section_id: section_ids, user_id: @current_user, role: role).exists?
  end
  private :any_role_for?

  def current_focus_has_sections?
    @current_focus.sections.present?
  end
  private :current_focus_has_sections?
end
