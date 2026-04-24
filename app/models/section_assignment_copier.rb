class SectionAssignmentCopier < Struct.new(:section_copy_id, :section_id)
  M3_COLUMN_NAMES = %i[
    assignable_id
    assignable_type
    category_id
    due_date
    individually_assignable
    rank
    section_id
    track_group_id
  ].freeze

  GRADEBOOK_COLUMN_NAMES = %i[
    activity_id
    category_id
    day_id
    individually_assignable
    lesson_id
    section_id
    strand_id
    week_id
  ].freeze

  def copy_assignments
    return if assignments_to_copy.nil?

    assignments_to_copy.each do |original_assignment|
      copied_assignment = original_assignment.dup
      if assignment_details?(original_assignment)
        process_assessment(original_assignment, copied_assignment)
        next
      end

      m3_and_gradebook_copy(original_assignment, copied_assignment)
    end
    save_assignments
  end

  private def assignment_details?(original_assignment)
    [
      original_assignment.password.present?,
      original_assignment.time_limit.positive?,
      original_assignment.number_of_attempts.present?,
      original_assignment.individually_assignable?
    ].any?
  end

  private def assignments_to_copy
    @assignments_to_copy ||= Assignment.select(
      'assignments.*, aad.id as aad_id, aad.password, ' \
      'aad.time_limit, aad.number_of_attempts, ' \
      'gcac.group_maximum, gcac.group_minimum'
    ).joins(
      'LEFT OUTER JOIN assigned_assessment_details aad ' \
      'ON aad.assignment_id = assignments.id ' \
      'LEFT OUTER JOIN group_chat_assignment_configs gcac ' \
      'ON gcac.assignment_id = assignments.id'
    ).where(section_id: section_copy_id).by_type(Activity).includes(:assignable)
  end

  private def m3_and_gradebook_copy(original_assignment, copied_assignment)
    original_gchat_assignments << original_assignment if has_gchat_config?(original_assignment)

    m3_copy(copied_assignment)
    gradebook_copy(copied_assignment)
  end

  private def has_gchat_config?(original_assignment)
    [
      original_assignment.group_maximum.present?,
      original_assignment.group_minimum.present?
    ].any?
  end

  private def bulk_assignments
    @bulk_assignments ||= []
  end

  private def bulk_gradebook_assignments
    @bulk_gradebook_assignments ||= []
  end

  private def original_gchat_assignments
    @original_gchat_assignments ||= []
  end

  private def assignments_with_details
    @assignments_with_details ||= []
  end

  private def m3_copy(copied_assignment)
    bulk_assignments << column_values(copied_assignment)
  end

  private def gradebook_copy(copied_assignment)
    bulk_gradebook_assignments << gradebook_column_values(copied_assignment)
  end

  private def save_assignments
    # We need to make a separate insert to the Gradebook for assignments
    # because the bulk import does not trigger the usual callback
    # Assignments with details save normally and keep the callback
    # so we do not need to do the additional save to the Gradebook db
    Assignment.import(M3_COLUMN_NAMES, bulk_assignments)
    GradebookEngine::Assignment.import(
      GRADEBOOK_COLUMN_NAMES,
      bulk_gradebook_assignments,
      on_duplicate_key_ignore: true
    )

    create_gchat_assignment_configs if original_gchat_assignments.present?

    return if assignments_with_details.blank?

    Assignment.transaction { assignments_with_details.map(&:save!) }
  end

  private def create_gchat_assignment_configs
    gchat_assignment_config_creater = BulkGchatAssignmentConfigCreator.new(
      original_gchat_assignments,
      section_id
    )
    gchat_assignment_config_creater.create
  end

  private def process_assessment(original_assignment, copied_assignment)
    copied_assignment.section_id = section_id
    copied_assignment.individually_assignable = false
    copied_assignment.assigned_assessment_detail_attributes = {
      password: original_assignment.password,
      time_limit: original_assignment.time_limit,
      number_of_attempts: original_assignment.number_of_attempts
    }
    assignments_with_details << copied_assignment
  end

  private def column_values(assignment)
    [
      assignment.assignable_id,
      'Activity',
      assignment.category_id,
      assignment.due_date,
      assignment.individually_assignable,
      assignment.rank,
      section_id,
      assignment.track_group_id
    ]
  end

  private def gradebook_column_values(assignment)
    [
      assignment.assignable_id,
      assignment.category_id,
      assignment.due_date,
      assignment.individually_assignable,
      assignment.assignable.lesson_id,
      section_id,
      assignment.assignable.concept_id,
      ::Week.week_containing(assignment.due_date)
    ]
  end
end
