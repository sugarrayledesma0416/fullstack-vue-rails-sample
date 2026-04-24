class Gradebook::StudentPracticeTestPresenter
  INITIALIZED_KEYS = %i[program_id course_id student_id section_id lesson_id unit_id].freeze

  attr_accessor :section_id, :lesson_id, :program_id, :course_id, :student_id, :unit_id

  def initialize(opts = {})
    INITIALIZED_KEYS.each do |key|
      send("#{key}=", opts[key])
    end
  end

  def lesson_focus
    @lesson_focus ||= program.two_tier? ? Lesson.where(unit_id: selected_unit_id) : [find_or_first_lesson]
  end

  private def find_or_first_lesson
    # Protects against server errors if query string was bad.
    lessons.find { |lesson| lesson.id == selected_lesson_id } || lessons.first
  end

  def activity
    # In cases where there are data issues caused by iterations in content creation prior to making
    # a program live, this orders by creation date to ensure that only the most recently created
    # activities table entry is selected
    @activity ||= Activity
                  .where(
                    lesson_id: lesson_focus,
                    activity_type: 'diagnostic_v2'
                  )
                  .order(created_at: :desc)
                  .find { |a| a.content_object.formative_activities.any? }
  end

  def attempt
    return unless activity
    return @attempt if defined?(@attempt)

    @attempt ||= Attempt.find_by(user_id: student_focus.id,
                                 section_id: section_id,
                                 activity_id: activity.id,
                                 status_code: AttemptStatus::CODE_COMPLETED)
  end

  def set_data
    {
      program_id: program_id,
      course_id: course_id,
      section_id: section_id,
      student_id: student_focus&.id
    }
  end

  def student_focus
    return unless student_id
    @student_focus ||= find_student_in_section
  end

  def lessons
    @lessons ||= Lesson.joins(:unit).where(units: { program_id: program_id }).sort
  end

  def units
    program.units
  end

  def selected_lesson_id
    @selected_lesson_id ||= (lesson_id || lessons.first.id).to_i
  end

  def selected_unit_id
    @selected_unit_id ||= (unit_id || units.first.id).to_i
  end

  def section
    @section ||= Section.find(section_id)
  end

  private def find_student_in_section
    section.current_students_base.find(student_id) ||
    raise('Student is not in your section.')
  end

  private def program
    @program ||= Program.find(program_id)
  end
end
