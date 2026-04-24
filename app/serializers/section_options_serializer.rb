class SectionOptionsSerializer < ActiveModel::Serializer
  attributes :id, :course, :name, :latest_section_id, :time_zone, :instructor,
             :section_instructors, :instructor_creator_roles, :instructor_roles,
             :due_time_hour, :due_time_min, :due_time_ampm, :additional_info,
             :previous_sections, :class_days, :hide_owner_name, :open_to_students,
             :allow_enrollment_lock, :assignments_present, :days_to_show_assignment_due_date,
             :one_roster_linked, :autorostering_linked, :lti_roster_linked

  def previous_sections
    object.previous_sections_info
  end

  def one_roster_linked
    object.one_roster_linked?
  end

  def lti_roster_linked
    object.lti_roster_linked?
  end

  def autorostering_linked
    object.autorostering_linked?
  end
end
