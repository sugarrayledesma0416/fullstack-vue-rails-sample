class SectionsPresenter
  def initialize(current_user, current_program, params)
    @params = params.to_h.with_indifferent_access
    @current_user = current_user
    @params[:instructor_id] = @current_user.id
    @current_program = current_program
  end

  def section
    @section ||= if @params[:id].present?
      Section.find(@params[:id])
    else
      Section.new(@params) if course.present?
    end
  end

  def course
    @course ||= Course.including_templates.find(@params[:course_id])
  end

  def previous_sections_for_course
    @previous_sections_for_course ||= @current_user.sections.where(course_id: course.id)
  end

  def build_additional_instructors
    unless section.instructors.include?(section.instructor)
      section.section_instructors.build(:user_id => section.instructor_id,
                                        :role => SectionInstructor::INSTRUCTOR_CREATOR_ROLES[:instructor])
    end

    section.prospective_additional_instructors.each do |instructor|
      section.section_instructors.build(:user_id => instructor.id,
                                        :role => SectionInstructor::INSTRUCTOR_ROLES[:none])
    end
  end
end
