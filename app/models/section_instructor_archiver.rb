module SectionInstructorArchiver

  def self.included(klass)
    klass.after_save :archive_section_instructors, :if => :archived?
    klass.after_destroy :archive_section_instructors
  end

  def archive_section_instructors
    self.section_instructors.update_all(:is_archived => true)
  end
  private :archive_section_instructors
end
