module DemoCourseBuild
  class CourseDataCopier
    attr_reader :model_course, :demo_course, :demo_section, :students, :errors

    def initialize(model_course:, demo_course:, demo_section:, students:)
      @errors = ActiveModel::Errors.new(self)
      @model_course = model_course
      @demo_course = demo_course
      @demo_section = demo_section
      @students = students
    end

    def populate_demo_course_data
      copy_course_settings
      section = demo_course.sections.first

      Enrollment.enroll_demo_students(students, section)
      create_cloned_attempts(students)
      create_scores_and_grades
    end

    def copy_course_settings
      unless Maestro::CourseLicense.copy(model_course.guid, demo_course.guid)
        raise "Failed to copy course licenses from course #{model_course.id} to trial course #{demo_course.id}"
      end

      model_course.categories.each do |model_category|
        new_attrs = model_category.attributes.except('id')
        new_category = demo_course.categories.create(new_attrs)
        clone_assignments(model_category, new_category)
      end
    end

    def create_cloned_attempts(students)
      students.each_with_index do |student, index|
        model_student = model_data.model_students[(index % model_data.model_students.size)]
        copy_attempt_records(model_student, student)
      end
    end

    private def copy_attempt_records(from_student, to_student)
      from_student.attempts.by_section(model_data.model_section).each do |attempt|
        new_attempt_params = attempt.attributes.merge('section_id' => demo_section.id)
        new_attempt_params.delete('id')
        new_attempt = to_student.attempts.create(new_attempt_params)
        copy_responses(attempt, new_attempt)
      end
    end

    private def copy_responses(old_attempt, new_attempt)
      if old_attempt.submitted_values?
        new_attempt.update(
          submission_id: new_attempt.results_datastore.write(
            old_attempt.results_datastore.stored_responses,
            :submitted
          )
        )
      elsif old_attempt.saved_values?
        new_attempt.update(
          saved_submission_id: new_attempt.results_datastore.write(
            old_attempt.results_datastore.saved_responses,
            :unsubmitted
          )
        )
      end
    end

    def create_scores_and_grades
      demo_section.attempts.each do |attempt|
        errors.add(:base, "using a non fake student on a demo course") unless attempt.user.fake?

        begin
          ::Gradebook::Submission.new(attempt.user, attempt.section, attempt.activity)
                                 .create_demo_score(attempt, submission_date(attempt.activity))
        rescue Exception => e
          msg = "DemoCourseSetup: error when submitting attempt ##{attempt.id} in course ##{id}."
          VHLMonitor.notify(e, {:error_message => msg})
        end
      end
    end

    private def clone_assignments(from_cat, to_cat)
      date_offset = (demo_course.start_date - model_course.start_date)
      from_cat.assignments.not_external.each do |assignment|
        new_due_date = (assignment.due_date + date_offset)
        new_attrs = assignment.attributes.merge(
          current: false,
          due_date: new_due_date.to_date,
          section_id: demo_section.id
        )
        new_attrs.delete('id')
        to_cat.assignments.create(new_attrs)
      end
    end

    private def model_data
      @model_data ||= ModelData.new(program: demo_course.program)
    end

    private def submission_date(activity)
      assignment = demo_section.assignments.by_activities(activity).first
      if assignment
        assigned_activity_submission_date(assignment)
      else
        unassigned_activity_submission_date
      end
    end

    private def assigned_activity_submission_date(assignment)
      if should_be_late?
        assignment.due_date_time + rand_offset(demo_course.end_date - assignment.due_date)
      else
        assignment.due_date_time - rand_offset(assignment.due_date - demo_course.start_date)
      end
    end

    def unassigned_activity_submission_date
      demo_course.start_date + rand_offset(demo_course.end_date - demo_course.start_date)
    end

    private def rand_offset(possible_days)
      rand(possible_days.days.to_i)
    end

    private def should_be_late?
      rand(8) > 7 # one in 8 assignments late
    end

  end
end
