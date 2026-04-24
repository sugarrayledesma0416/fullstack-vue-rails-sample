class CourseOwnerTransferor
  attr_reader :course, :current_user, :destination_instructor, :errors

  def initialize(course, current_user, destination_instructor)
    @course = course
    @current_user = current_user
    @destination_instructor = destination_instructor
    @errors = []
    @original_owner_id = course.owner_id
  end

  def transfer
    if course.owner != current_user
      @errors << 'Only the owner of the course can transfer the course.'
    elsif !current_user.institution_admin?
      @errors << 'Only an institution admin can transfer courses.'
    else
      transfer_course
    end
    @errors.empty?
  end

  private def transfer_course
    if course.update(owner_id: destination_instructor.id)
      course.sections.each do |section|
        transfer_section(section)
      end
    else
      @errors += course.errors.full_messages
    end
  end

  private def transfer_section(section)
    if section.update(instructor_id: destination_instructor.id)
      transfer_section_instructors_and_forums(section)
    else
      @errors += section.errors.full_messages
    end
  end

  private def transfer_section_instructors_and_forums(section)
    section.section_instructors
           .where(user_id: @original_owner_id).each do |section_instructor|
      section_instructor.update(user_id: destination_instructor.id)
    end
    section.forums.where(instructor_id: @original_owner_id).each do |forum|
      forum.update(instructor_id: destination_instructor.id)
    end
  end
end
