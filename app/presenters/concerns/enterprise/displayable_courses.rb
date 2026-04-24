module Enterprise
  module DisplayableCourses
    private def courses_by_school_current_or_later_year
      courses_by_school.where('courses.end_date >= ?', Date.new(@current_year))
    end

    private def courses_by_school_current_or_later_year_non_enterprise
      courses_by_school_non_enterprise.where('courses.end_date >= ?', Date.new(@current_year))
    end

    # Finds non-demo courses for the school.
    #
    # Also left-joins to hidden courses for the current user:
    #   methods that chain onto this one can check for a null in the joined
    #   subquery to determine if the user has hidden the course.
    private def courses_by_school
      @courses_by_school ||= school
                             .courses
                             .enterprise
                             .joins(%( left join (
                                         #{user_hidden_courses_subquery}
                                       ) hidden_courses_for_user
                                       on courses.id = hidden_courses_for_user.course_id ))
                             .where(is_demo: false)
    end

    private def courses_by_school_non_enterprise
      @courses_by_school_non_enterprise ||= school
                                           .courses
                                           .non_enterprise
                                           .joins(%( left join (
                                                       #{user_hidden_courses_subquery}
                                                     ) hidden_courses_for_user
                                                     on courses.id = hidden_courses_for_user.course_id ))
                                           .where(is_demo: false)
    end

    # Returns SQL for the current user's hidden courses.
    private def user_hidden_courses_subquery
      InstitutionAdminHiddenCourse
        .select(:course_id)
        .where(user_id: current_user.id)
        .to_sql
    end
  end
end
