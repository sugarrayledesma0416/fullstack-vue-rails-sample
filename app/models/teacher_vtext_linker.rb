class TeacherVtextLinker < VtextLinker

  def vtext_link
    @program_settings.teacher_vtext_link
  end

  def menu_linkable?
    @user.instructor? && program_has_teacher_vtext?
  end

  def program_has_teacher_vtext?
    @program_settings.has_teacher_vtext_link?
  end
  private :program_has_teacher_vtext?

  alias_method :program_has_vtext?, :program_has_teacher_vtext?

  def link_label
    if @program_settings.teacher_vtext_label.blank?
      @program.vista_online_learning? ? "Instructor's Manual" : "Teacher's Edition"
    else
      @program_settings.teacher_vtext_label
    end
  end
end


