require 'etl/category_etl'
class GbCategoryMigrator < AbstractGbObjectMigrator
  def model_name
    'Category'
  end

  # merge in the related course's school_id
  def attributes_for_gb_update(m3_obj)
    m3_obj.attributes.merge('school_id' => m3_obj.course.school_id)
  end
end
