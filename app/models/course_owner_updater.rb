class CourseOwnerUpdater
  attr_reader :course, :previous_owner, :new_owner
  attr_accessor :errors

  def initialize(course, new_owner)
    @course = course
    @previous_owner = course.owner
    @new_owner = new_owner
    @previous_owner.extend(CourseOwnerUtilities)
    @new_owner.extend(CourseOwnerUtilities)
    self.errors = []
  end

  def update
    return unless valid?

    Course.transaction do
      course.update!(owner_id: new_owner.id)

      course.sections.each do |section|
        transfer_section(section)
      end
    end
  end

  private def transfer_section(section)
    section.update!(instructor_id: new_owner.id)

    transfer_section_instructors_and_forums(section)
  end

  private def transfer_section_instructors_and_forums(section)
    section.section_instructors.where(
      user_id: previous_owner.id
    ).destroy_all

    section_instructors = section.section_instructors.where(
      user_id: new_owner.id
    )
    if section_instructors.exists?
      section_instructors.find_each do |section_instructor|
        section_instructor.update!(role: 'Instructor')
      end
    else
      SectionInstructor.create(
        section: section,
        user_id: new_owner.id,
        role: 'Instructor',
        show: true
      )
    end

    section.forums.where(instructor_id: previous_owner.id).find_each do |forum|
      forum.update!(instructor_id: new_owner.id)
    end
  end

  private def valid?
    validations.all? do |validation|
      send(validation)
      errors.empty?
    end
  end

  private def validations
    %i[validate_course validate_owners]
  end

  private def validate_owners
    unless previous_owner.allows_rostering_course_transfer?
      errors << "#{previous_owner.full_name} is not a " \
        "#{CourseOwnerUtilities::ALLOWED_TYPES_FOR_TRANSFER} instructor."
      return # We can't transfer the course ownership.
    end

    if new_owner.allows_rostering_course_transfer?
      validate_new_owner
    else
      errors << "#{new_owner.full_name} is not a " \
        "#{CourseOwnerUtilities::ALLOWED_TYPES_FOR_TRANSFER} instructor."
    end
  end

  private def validate_new_owner
    if !previous_owner.other_instructor_same_type?(new_owner)
      errors << "#{new_owner.full_name} is not a #{previous_owner.instructor_type} instructor."
    elsif (new_owner.schools & previous_owner.schools).blank?
      errors << "#{new_owner.full_name} is not an instructor " \
        'in a school the current owner belongs to.'
    end
  end

  private def validate_course
    if course.closed? && !course.editable?
      errors << 'The course is closed.'
    elsif course.is_archived
      errors << 'The course is archived.'
    end
  end
end
