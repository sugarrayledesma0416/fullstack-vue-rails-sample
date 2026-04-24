module ForumAccessProtection
  # Use this method as a before_action to restrict forum access to
  # students enrolled in the section to which the forum belongs or
  # members of the instructor team for that section.
  # Requires @forum to be assigned before the before_action is called.
  private def restrict_forum_access
    # Don't let kids edit the DOM and post rude stuff to random forums.
    unless enrolled_student? || instructor_team_instructor?
      redirect_intruder
    end
  end

  private def redirect_intruder
    flash[:error] = 'Some good unauthorized access message'
    redirect_to BestDefaultPath.best_default_path(
      current_user, current_program, current_section, session
    )
  end

  private def enrolled_student?
    current_user.student? && current_user.enrolled_in?(@forum.section)
  end

  private def instructor_team_instructor?
    current_user.instructor? && current_user.sections.include?(@forum.section)
  end
end
