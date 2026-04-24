class UnitSerializer < ActiveModel::Serializer
  attributes :name, :id, :media_item_filename

  def media_item_filename
    object.media_item&.public_filename ||
      ActionController::Base.helpers.asset_path('jr/icons/strand_default.svg')
  end

  def as_json(options = nil)
    section = options.nil? ? { course: nil } : options[:section]
    {
      name: object.display_name,
      id: object.id,
      media_item_filename: object.media_item&.public_filename ||
        ActionController::Base.helpers.asset_path('jr/icons/strand_default.svg'),
      in_course: section.course.nil? ? true : section.units.include?(object),
      two_tier: options[:two_tier],

      lessons: object.lessons.sort_by(&:rank).map do |lesson|
        lesson.as_json(except: [:toc_entries_xml, :unit_id, :use_type])
      end
    }
  end
end
