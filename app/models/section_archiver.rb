class SectionArchiver
  # handles both archiving cases - regular section
  # and cases where not just the section gets archived,
  # but all sections and the course (LTI-Adv)

  attr_accessor :errors, :success_message

  def initialize
    self.errors = []
  end

  def archive(section)
    if section.lti_roster_linked?
      destroy_linked_content(section)
    else
      section.archive
      if section.errors.empty?
        self.success_message = "Section <b>#{section.name}</b> was deleted successfully."
      else
        self.errors += section.errors.full_messages
      end
    end
    self.errors.empty?
  end

  def error_message
    self.errors.join('<br/>')
  end

  private def destroy_linked_content(section)
    # LTI created courses should only have one section.
    # ensure that both course ans section are deleted together
    course = section.course
    Course.transaction do
      course.sections.each do |section|
        section.archive
        self.errors += section.errors.full_messages if section.errors.present?
      end
      if self.errors.empty?
        course.reload
        course.archive
        self.errors += course.errors.full_messages if course.errors.present?
      end
    end
    if self.errors.empty?
      self.success_message = "Course <b>#{course.name}</b> and its sections were deleted successfully."
    end
  end
end
