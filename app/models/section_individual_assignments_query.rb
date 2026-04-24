module SectionIndividualAssignmentsQuery
  ASSIGNMENT_SELECT_TEMPLATE = <<~SQL.freeze
    activities.title as activity_title,
    assignments.assignable_id,
    assignments.individually_assignable,
    assignments.due_date,
    assignments.section_id,
    concepts.id as strand_id,
    concepts.name as strand_name,
    concepts.background_color as strand_color,
    ia.id as individually_assigned,
    ia.due_date as individual_due_date,
    ia.due_date as last_individual_due_date,
    assignments.assignable_id in (
      select activity_id
      from   individual_assignments
      where  section_id = %d
             and individual_assignments.due_date is not null
    ) as show_due_date_field,
    users.id as user_id,
    users.first_name,
    users.last_name
  SQL

  ASSIGNMENT_JOIN = <<~SQL.freeze
    INNER JOIN concepts ON concepts.id = activities.concept_id
    INNER JOIN lessons ON lessons.id = activities.lesson_id
    INNER JOIN units ON units.id = lessons.unit_id
    LEFT OUTER JOIN individual_assignments ia ON
       ia.user_id = users.id AND
       ia.section_id = assignments.section_id AND
       ia.activity_id = activities.id
  SQL

  def assignments(section_id)
    Assignment.by_type(Activity).select(
      format(ASSIGNMENT_SELECT_TEMPLATE, section_id)
    ).joins(
      [section: :current_students_base]
    ).joins(ASSIGNMENT_JOIN).where(section_id: section_id).order(
      'users.last_name, users.first_name, assignments.due_date, ' \
      'units.rank, lessons.rank, concepts.rank, activities.concept_rank, ' \
      'activities.id'
    )
  end
  module_function :assignments
end
