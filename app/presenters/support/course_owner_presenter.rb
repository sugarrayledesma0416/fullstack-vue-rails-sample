module Support
  class CourseOwnerPresenter
    attr_reader :instructor

    def initialize(instructor)
      @instructor = instructor
      @instructor.extend(CourseOwnerUtilities)
    end

    def instructor_username
      if instructor.one_roster?
        instructor.one_roster_linked_user.external_username
      else
        instructor.username
      end
    end

    def courses
      @courses ||= instructor.open_courses
    end

    def courses_by_program
      @courses_by_program = courses.group_by(&:program)
    end

    def possible_owners_by_course(course)
      @possible_owners_by_course ||= courses.to_h do |course|
        # The new owner can be any valid instructor in one of the schools the
        # current owner belongs to.
        if @instructor.allows_rostering_course_transfer?
          [course, @instructor.same_type_instructors_in_school]
        end
      end
      @possible_owners_by_course[course]
    end
  end
end
