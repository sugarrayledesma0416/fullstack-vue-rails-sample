require 'etl/assignment_etl'
class GbAssignmentMigrator < AbstractGbObjectMigrator
  def model_name
    'Assignment'
  end

  # merge in attributes from related activity and section
  # required by the GradebookEngine::Assignment instance
  def attributes_for_gb_update(m3_obj)
    m3_obj.attributes.merge('lesson_id' => m3_obj.assignable.lesson_id,
                             'concept_id' => m3_obj.assignable.concept_id,
                             'school_id' => m3_obj.section.course.school_id)
  end

  def m3_model_name
    'Assignment'
  end
end
