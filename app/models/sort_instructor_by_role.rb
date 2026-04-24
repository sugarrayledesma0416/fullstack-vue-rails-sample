class SortInstructorByRole
  ROLE_PRIORITY = {
    SectionInstructor::INSTRUCTOR_ROLE => 0,
    SectionInstructor::COINSTRUCTOR_ROLE => 1,
    SectionInstructor::ASSISTANT_ROLE => 3
  }.freeze

  def initialize(section)
    @section_instructors = section.section_instructors.includes(:instructor)
  end

  def call
    return [] if @section_instructors.blank?

    if @section_instructors.select { |x| x.role.blank? }.any?
      @section_instructors.map{ |si| { instructor: si.instructor, role: si.role } }
    else
      @section_instructors
        .sort_by{ |si| (ROLE_PRIORITY[si.role] rescue 0) }
        .map{ |si| { instructor: si.instructor, role: si.role } }
    end
  end
end
