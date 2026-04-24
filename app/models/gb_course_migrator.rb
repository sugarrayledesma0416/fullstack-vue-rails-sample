require 'etl/course_etl'
class GbCourseMigrator < AbstractGbObjectMigrator
  def model_name
    'Course'
  end

  # merge in the current events unit id if
  # one is defined for this course's program
  def attributes_for_gb_update(m3_obj)
    current_events_unit_id = m3_obj.program.current_events_unit && m3_obj.program.current_events_unit.id
    m3_obj.attributes.merge('current_events_unit_id' => current_events_unit_id)
  end
end
