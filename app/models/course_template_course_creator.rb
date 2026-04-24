class CourseTemplateCourseCreator
  attr_accessor :course, :course_name, :course_template, :course_owner_id,
                :source_template_id, :hide_from_dash

  def initialize(params)
    self.course_name = params[:name]
    self.course_owner_id = params[:owner_id]
    self.source_template_id = params[:source_template_id]
    self.hide_from_dash = params[:hide_from_dash_checkbox_status]

    # Validate that template exists.
    return unless Course.templates.where(id: source_template_id).empty?

    raise "There is no course template with id = #{source_template_id}."
  end

  def create_course
    # Make a copy of the course template.
    self.course_template = Course.templates.find(source_template_id)
    self.course = course_template.dup

    # TODO: validate that course owner is an instructor with access to
    #       program in school
    update_course_attrs
    copy_course_licenses
    copy_categories
    copy_course_library

    course.id
  end

  # Change column values, including marking the copy as a real course.
  # NOTE: The GUID is set to nil so that a new GUID will be assigned automatically.
  private def update_course_attrs
    course.update!(
      guid: nil,
      hide_from_instructor_dashboard: hide_from_dash,
      is_template: false,
      name: course_name,
      owner_id: course_owner_id,
      source_template_id: source_template_id
    )
  end

  private def copy_course_library
    CourseLibraryActivity.transaction do
      course_library_activity_ids.each do |activity_id|
        CourseLibraryActivity.create!(
          activity_id: activity_id, course_id: course.id, hidden: true
        )
      end
    end
  end

  private def course_library_activity_ids
    SharedLibraryActivity.joins(activity: { lesson: :unit }).where(
      shared_library_activities: {
        is_shared: true, school_id: course_template.school_id
      },
      units: { program_id: course_template.program_id }
    ).pluck(:activity_id)
  end

  private def copy_course_licenses
    Retryable.retryable(tries: 6, sleep: lambda { |n| 2**n }) do
      unless Maestro::CourseLicense.copy(course_template.guid, course.guid)
        raise 'Failed to copy course licenses from template course ' \
              "#{course_template.id} to course #{course.id}"
      end
    end
  end

  # Copy the template categories and assign them to the new course.
  private def copy_categories
    Category.where(course: course_template).find_each do |category|
      category_copy = category.dup
      category_copy.course_id = course.id
      category_copy.save!
    end
  end
end
