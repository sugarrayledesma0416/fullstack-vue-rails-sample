module AssignmentSorter
  ASSIGNMENT_JOINS = <<~SQL.squish.freeze
    INNER JOIN concepts ON concepts.id = activities.concept_id
    INNER JOIN lessons ON lessons.id = activities.lesson_id
    INNER JOIN units ON units.id = lessons.unit_id
    LEFT OUTER JOIN assignment_sets ON
      assignment_sets.section_id = assignments.section_id AND
      assignment_sets.due_date = assignments.due_date
    LEFT OUTER JOIN assignment_set_activities asa ON
      asa.activity_id = assignments.assignable_id AND
      asa.assignment_set_id = assignment_sets.id
  SQL

  ASSIGNMENT_ORDER = <<~SQL.squish.freeze
    units.rank,
    lessons.rank,
    concepts.rank,
    activities.concept_rank,
    activities.toc_location_rank
  SQL

  def sort_by_due_date_and_rank(assignments)
    # The due-date sort is in Ruby rather than SQL so that the assignments argument may be
    # either a database scope (when called from app/models/section_learning_track.rb)
    # or an array (when called from app/models/classwork_filter.rb).
    assignments.sort_by(&:due_date)
               .group_by(&:due_date)
               .map do |_, v|
                 v.sort do |a, b|
                   a.rank == b.rank ? a.assignable <=> b.assignable : a.rank <=> b.rank
                 end
               end.flatten
  end
  private :sort_by_due_date_and_rank
end
