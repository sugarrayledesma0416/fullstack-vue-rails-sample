class Focus

  attr_reader :program_id, :section_id, :program

  def initialize(user, program, opts = {})
    @user = user
    @program = program
    @opts = opts

    if opts_program_id && valid_section?(opts_program_id['section_id'])
      @section_id = opts_program_id['section_id']
    end
  end

  def program_id
    @program.id
  end

  delegate :closed?, :editable?, :end_date, :name, :open?, :start_date,
           to: :course,
           allow_nil: true,
           prefix: true

  def same_school_as_course?(school)
    school && course && (course.school_id == school.id)
  end

  def course_id
    if opts_program_id
      @course_id = opts_program_id['course_id']
    elsif @course
      @course_id = @course.id
    end
  end

  def section_name
    section.name if section.present?
  end

  def section_names
    sections.collect(&:name)
  end

  def type_and_id
    return "Section,#{@section_id}" if @section_id
    "Course,#{course_id}"
  end

  def css_type_and_id
    type_and_id.gsub(',', '_').underscore
  end

  def type
    type_and_id.split(',')[0].downcase
  end

  def course
    return @course if @course
    begin
      if opts_template_flag
        @course = Course.enterprise.find(course_id)
        @sections = @course.sections.to_a
      elsif course_id
        @course = Course.find(course_id)
      elsif @section_id
        @section = Section.find(@section_id)
        @course = @section.course
      end
    rescue ActiveRecord::RecordNotFound
    ensure
      @course ||= default_focus
    end
    @course
  end

  def course_school_id
    course.school_id if course
  end

  def sections
    return @sections if @sections
    @sections = []
    if @section_id
      @sections = Section.where(id: @section_id)
    else
      @sections = course.sections_by_instructor(@user) if course
    end
    @sections.to_a
  end

  def all_sections_in_course
    course.sections_by_instructor(@user)
  end

  def has_atleast_one_actionable_section?
    raise "focus not supported for this type of user" if !@user || @user.student?
    course.present? && sections.present?
  end

  def class_days
    return [] if type == 'course' && course.section_class_days_vary?
    day_str = sections.inject('') { |s, section| s << "#{section.class_days}," }
    day_str.split(',').sort.uniq
  end

  def student_sorter
    @student_sorter ||= if opts_program_id && opts_program_id['sort']
      StudentSorter.new(sections, opts_program_id['sort'])
    else
      StudentSorter.new(sections)
    end
  end

  def sort_params
    { :column => sort_column, :direction => sort_direction, :category_id => sort_category_id }
  end

  def sort_column
    student_sorter.column
  end

  # TODO: add wrappers for sort_asc?, sort_desc?
  def sort_direction
    student_sorter.direction
  end

  def sort_category_id
    student_sorter.category_id
  end

  def students_in_all_sections
    @students_in_all_sections ||= course.sections_by_instructor(@user).map { |section| section.students }.flatten
  end

  def allowed_to_view_student?(student)
    students_in_all_sections.include?(student)
  end

  def students
    student_sorter.students
  end

  def section
    sections.first if sections
  end

  def focused_on_course?
    course.present? && (course.sections_by_instructor(@user) - sections).empty?
  end

  def focused_on_section?
    focused? && @section_id
  end

  def focused?
    course.present? || @section.present?
  end

  def focused_on_only_one_section?
    has_atleast_one_actionable_section? && sections.size == 1
  end

  def course_and_section_params
    {}.tap do |hsh|
      hsh[:course] = course
      hsh[:section] = section if focused_on_only_one_section?
    end
  end

  def template?
    opts_template_flag
  end

  # will return nil if the user has no courses for the current progam
  def default_focus
    program = Program.find_by_id(program_id) || @program
    course = @user.courses_and_sections_for_focus(program).keys.first
    @section_id = nil  # set to nil so course has focus
    course
  end
  private :default_focus

  def valid_section?(section_id)
    Section.find_by_id(section_id).present?
  end
  private :valid_section?

  private def opts_program_id
    return @opts_program_id if defined?(@opts_program_id)
    @opts_program_id = @opts && @opts[program_id.to_s]
  end

  private def opts_template_flag
    return @opts_template_flag if defined?(@opts_template_flag)
    @opts_template_flag = @opts && @opts['template']
  end
end
