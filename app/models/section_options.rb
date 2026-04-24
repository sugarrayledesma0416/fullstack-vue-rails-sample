class SectionOptions
  include ActiveModel::Serialization
  include UserEmailHelper

  attr_reader :section

  delegate :id, :name, :hide_owner_name, :open_to_students,
           :days_to_show_assignment_due_date, :one_roster_linked?, :lti_roster_linked?,
           :autorostering_linked?,
           to: :section

  def initialize(user, section, previous_sections = [])
    @section = section
    @previous_sections = previous_sections
    @user = user # User who's trying to create / edit a section
  end

  def instructor_creator_roles
    SectionInstructor::INSTRUCTOR_CREATOR_ROLES.values.sort
  end

  def instructor_roles
    SectionInstructor::INSTRUCTOR_ROLES.values
  end

  private def block_enrollment_policy
    @block_enrollment_policy ||= Policy::Section::BlockEnrollment.new(@user)
  end

  def allow_enrollment_lock
    block_enrollment_policy.can?
  end

  def course
    { id: @section.course_id, name: @section.course.name, program_id: @section.course.program_id, owner_id: @section.course.owner_id }
  end

  def time_zone
    @section.time_zone || Time.zone.name
  end

  def instructor
    { id: @section.instructor.id }
  end

  def section_instructors
    @section_instructors ||= section_instructors_info(@section.section_instructors)
  end

  def due_time_hour
    (@section.due_time && @section.due_time.strftime('%l').strip) || '11'
  end

  def due_time_min
    (@section.due_time && @section.due_time.strftime('%M').strip) || '59'
  end

  def due_time_ampm
    (@section.due_time && @section.due_time.strftime('%p')) || 'PM'
  end

  def latest_section
    @latest_section ||= @previous_sections.sort_by(&:created_at).last
  end

  def latest_section_id
    (latest_section && latest_section.id) || 0
  end

  def additional_info
    @section.additional_info || ''
  end

  def previous_sections_info
    @previous_sections.map do |section|
      {
        additional_info: section.additional_info,
        assignment_past_due_count: section.assignment_past_due_count,
        class_days: Hash[(
          # converts "1,2" to {"1" => true, "2" => true}
          section.class_days.split(',').map { |i| [i, true] }
        )],
        course: { id: section.course.id, name: section.course.name },
        due_time_ampm: section.due_time.strftime('%p').strip,
        due_time_hour: section.due_time.strftime('%l').strip,
        due_time_min: section.due_time.strftime('%M').strip,
        # FIXME: When we add external assignments to section templates, we will need
        #        the section template to be synced to GradebookEngine.
        has_external_assignments: GradebookEngine::Section.find_by(id: section.id)
                                                          &.external_assignments
                                                          &.any?,
        hide_owner_name: section.hide_owner_name,
        id: section.id,
        name: section.name,
        section_instructors: section_instructors_info(section.section_instructors),
        time_zone: section.time_zone,
        assignments_present: section.assignments.any?
      }
    end
  end

  def section_instructors_info(section_instructors)
    section_instructors.map do |si|
      {
        allowed_to_edit_content: si.allowed_to_edit_content?,
        first_name: si.instructor.first_name,
        full_name: si.instructor.full_name,
        last_name: si.instructor.last_name,
        email: user_display_email(si.instructor),
        role: si.role,
        user_id: si.user_id
      }.tap { |memo| memo[:id] = si.id if si.id.present? }
    end
  end

  def class_days
    @section.class_days ? Hash[(@section.class_days.split(',').map { |i| [i, true] })] : {} # converts "1,2" to {"1" => true, "2" => true}
  end

  def assignments_present
    @section.assignments.any?
  end
end
