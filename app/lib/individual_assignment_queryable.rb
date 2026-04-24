module IndividualAssignmentQueryable
  INDIVIDUAL_ASSIGNMENT_GRADING_SET_SELECT = <<~SQL.freeze
    assignments.assignable_id as activity_id,
    assignments.individually_assignable,
    enrollments.user_id,
    individual_assignments.id as individually_assigned
  SQL

  INDIVIDUAL_ASSIGNMENT_GRADING_SET_JOIN = <<~SQL.freeze
    LEFT OUTER JOIN individual_assignments
      ON individual_assignments.activity_id = assignments.assignable_id
      AND individual_assignments.section_id = assignments.section_id
      AND individual_assignments.user_id = enrollments.user_id
  SQL

  DUE_DATE_COALESCE = <<~SQL.freeze
    coalesce(individual_assignments.due_date, assignments.due_date)
  SQL

  private def apply_individual_assignment_filter(scope, user_id)
    scope
      .joins(individual_assignments_join(user_id))
      .where(individual_assignments_condition)
      .select('assignments.*')
      .select("#{DUE_DATE_COALESCE} as due_date")
  end

  private def individual_assignments_join(user_id)
    %(
      LEFT OUTER JOIN individual_assignments
        ON individual_assignments.activity_id = assignments.assignable_id
        AND individual_assignments.section_id = assignments.section_id
        AND individual_assignments.user_id = #{user_id}
    )
  end

  private def individual_assignments_condition
    'assignments.individually_assignable = 0 OR ' \
    'individual_assignments.id IS NOT NULL'
  end

  private def individual_assignment_grading_set_scope(activities, sections)
    Assignment.by_type(Activity).select(
      INDIVIDUAL_ASSIGNMENT_GRADING_SET_SELECT
    ).joins(
      'INNER JOIN enrollments ON enrollments.section_id = assignments.section_id'
    ).joins(INDIVIDUAL_ASSIGNMENT_GRADING_SET_JOIN).where(
      assignments: { assignable_id: activities, section_id: sections },
      enrollments: { state: %w[enrolled marked_complete] }
    )
  end
end
