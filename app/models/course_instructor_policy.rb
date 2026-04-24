class CourseInstructorPolicy
  attr_accessor :course, :user

  def initialize(course, user)
    self.course = course
    self.user = user
  end

  def editing_instructor?
    course_owner? || editing_coinstructor?
  end

  def course_owner?
    course.owner_id == user.id
  end

  private def editing_coinstructor?
    course.sections.joins(:section_instructors).where(
      section_instructors: {
        allowed_to_edit_content: true,
        is_archived: false,
        role: SectionInstructor::COINSTRUCTOR_ROLE,
        instructor: user
      }
    ).exists?
  end
end
