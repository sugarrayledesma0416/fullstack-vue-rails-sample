class ActiveEnrollmentAccessUpdater
  attr_reader :student, :section

  # Compared to the ActiveEnrollmentAccessUpdater that exists on UA
  # this one only works by a section by section basis.
  # The reason is that the ids returned from the call to Maestro::Enrollment.check_licenses
  # might not match the enrollment ids in M3. So we only do a call by one enrollment
  # and check if the results are not empty. If they are not empty it means that
  # the enrollment needs to be updated with sufficient_access = TRUE
  def initialize(student, section)
    @student = student
    @section = section
  end

  def update
    return unless student_enrollment.present? && enrollment_needs_update?

    student_enrollment.update(sufficient_access: true)
  end

  private def student_enrollment
    @student_enrollment ||= student.enrollments.active.find_by(section_id: section)
  end

  private def enrollment_needs_update?
    return false if student_enrollment.sufficient_access

    # Check the results from API to know if the enrollment needs to be updated.
    enrollments_from_api['enrollment_ids'].present?
  end

  private def enrollments_from_api
    Maestro::Enrollment.check_licenses(
      [student_enrollment.guid]
    )
  end
end
