require 'etl/lesson_etl'
class GbLessonMigrator < AbstractGbObjectMigrator
  def model_name
    'Lesson'
  end

  # merge in the related unit's rank
  # which is required by the GradebookEngine::Lesson instance
  def attributes_for_gb_update(m3_obj)
    m3_obj.attributes.merge('unit_rank' => m3_obj.unit.rank, 'unit_id' => m3_obj.unit.id, 'program_id' =>  m3_obj.unit.program_id)
  end

end
