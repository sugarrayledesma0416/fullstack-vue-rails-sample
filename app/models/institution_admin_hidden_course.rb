class InstitutionAdminHiddenCourse < ApplicationRecord
  def self.hide_courses(user, program, course_ids_to_hide)
    already_hidden = existing_hidden_course_ids(user, program)

    to_be_hidden = restrict_to_program(course_ids_to_hide, program)

    # Find [existing hidden courses] - [courses to hide]
    #   and delete those hidden-course records
    destroy(where(course_id: already_hidden - to_be_hidden,
                  program_id: program.id,
                  user_id: user.id)
            .map(&:id))

    # Find [courses to hide] - [existing hidden courses]
    #   and create those hidden-course records
    create((to_be_hidden - already_hidden).map do |course_id|
      { course_id: course_id, program_id: program.id, user_id: user.id }
    end)
  end

  # Gets array of IDs for existing hidden courses for user and program.
  def self.existing_hidden_course_ids(user, program)
    where(program_id: program.id,
          user_id: user.id)
      .map(&:course_id)
  end

  # Rejects any to-be-hidden course IDs not associated with the program.
  #   While I don't foresee that any such course IDs will be in the array,
  #   this is an extra guard against hiding more than was intended.
  def self.restrict_to_program(course_ids, program)
    Course.find(course_ids)
          .select { |course| course.program_id == program.id }
          .map(&:id)
  end
end
