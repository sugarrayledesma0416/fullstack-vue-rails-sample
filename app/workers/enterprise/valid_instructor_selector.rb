module Enterprise
  module ValidInstructorSelector
    # used by AssignActivityWorker and UnassignActivityWorker
    # to get a valid instructor
    def valid_instructor(instructor_id, course_id)
      role = ['Instructor', 'Co-instructor']
      course = Course.find_by(id: course_id)
      institution_admin = InstitutionAdmin.find_by(id: instructor_id)
      return institution_admin if institution_admin

      section_ids = course.sections.pluck(:id)
      section_instructor = SectionInstructor.exists?(
        section_id: section_ids,
        user_id: instructor_id,
        role:
      )

      if section_instructor
        instructor = Instructor.find_by(id: instructor_id)
        return instructor
      end
      nil
    end
  end
end
