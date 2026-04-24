module BulkAssignmentWorkerSetup
  # used by BulkAssignmentWorker -
  # essential setup code that is used to bulk import assignments
  # into the M3 and Gradebook databases -
  # - look ups of Course and Sections
  # - create Hash of category map
  # - turn the assignments into "work items" spread out
  #   over the assignment calendar

  def setup(section_ids, course_id, raw_assignments, category_map, source_section_id)
    @course = Course.find(course_id)
    @sections = Section.including_enterprise.where(id: section_ids)
    @source_section = Section.including_enterprise.find(source_section_id) if source_section_id
    # Using hashes with indifferent access because the hash keys are
    # strings, but the dependent code uses symbol keys.
    @category_map = ActiveSupport::HashWithIndifferentAccess.new(category_map)
    # spread the assignments over the activity calendar
    # assignment count used for logging purposes
    breakup_assignments(raw_assignments)
    # total is doubled because we are now importing the same set of assignments
    # into 2 databases - M3 and gradebook
    @total_work = @assignment_calendar_slices.length.to_f * 2
    at(0)
  end

  private def breakup_assignments(raw_assignments)
    assignments = ActiveSupport::HashWithIndifferentAccess.new(raw_assignments)
    # Ensure that assignment_slice_size is >= 1, if we were to somehow receive an
    # empty calendar, an exception would be thrown when we tried to
    # use a 0 slice size.
    assignment_slice_size = [1, (assignments.length / 10.0).floor].max
    # Break the assignment calendar into an array of assignment
    # calendar pieces.
    @assignment_calendar_slices = assignments.each_slice(assignment_slice_size).map { |slice| Hash[slice] }
    # For logging purposes
    @num_assignments = assignments.values.flatten.count
  end
end
