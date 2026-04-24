module Services
  class PubnubOpenCourses
    attr_reader :instructor, :courses_scope

    def initialize(instructor, courses_scope = nil)
      @instructor = instructor
      @courses_scope = courses_scope || instructor.open_courses
    end

    # Returns open courses visible to this instructor.
    # Includes when: no sections, any section has hide=false, owner archived, or no SI row.
    # Uses includes to avoid N+1; filters in SQL for correctness and performance.
    # return ActiveRecord::Relation collection of visible courses with preloaded associations
    # LEFT JOIN helpers for visibility checks (owner, eligible sections, section_instructors).
    # Note: sections must be non-archived and non-enterprise.
    def eligible_courses
      base_query
        .joins(owner_sql)
        .joins(sections_sql)
        .joins(section_instructors_sql)
        .where(visibility_rules)
        .distinct
    end

    # Base scope with required preloads.
    # return ActiveRecord::Relation preloaded open courses base scope
    private def base_query
      courses_scope.includes(:owner, sections: %i[current_students_base instructors])
    end

    # return String SQL fragment to LEFT JOIN course owner as owner_users
    private def owner_sql
      <<~SQL.squish
        LEFT OUTER JOIN users owner_users ON owner_users.id = courses.owner_id
      SQL
    end

    # return String SQL fragment to LEFT JOIN eligible sections (non-archived, non-enterprise)
    private def sections_sql
      <<~SQL.squish
        LEFT OUTER JOIN sections ON sections.course_id = courses.id
          AND sections.is_archived = FALSE
          AND (sections.is_enterprise = FALSE OR sections.is_enterprise IS NULL)
      SQL
    end

    # return String sanitized SQL to LEFT JOIN section_instructors for this instructor
    private def section_instructors_sql
      # Using sanitize_sql_array to prevent SQL injection
      ActiveRecord::Base.send(
        :sanitize_sql_array,
        [
          <<~SQL.squish,
            LEFT OUTER JOIN section_instructors si ON si.section_id = sections.id
              AND si.user_id = ?
              AND si.is_archived = FALSE
          SQL
          instructor.id
        ]
      )
    end

    # Courses are visible if:
    # They have no (eligible) sections (LEFT JOIN yields NULL), OR
    # The owner is archived, OR
    # There exists any section_instructor row for this instructor with
    # hide_from_instructor_dashboard = FALSE.
    # return String SQL predicate implementing course visibility OR conditions
    private def visibility_rules
      <<~SQL.squish
        sections.id IS NULL
        OR owner_users.archived = TRUE
        OR si.id IS NULL
        OR si.hide_from_instructor_dashboard = FALSE
      SQL
    end
  end
end
