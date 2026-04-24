#  encoding: utf-8

class LessonPublishProcessor
  include BasePublishProcessor

  VALID_ATTRIBUTES =  [:unit_toc_location,
                       :toc_entries_xml,
                       :rank,
                       :name,
                       :unit_id,
                       :label]

  REQUIRED_ATTRIBUTES = [:unit_toc_location, :rank, :name, :toc_entries_xml]

  def initialize(params)
    super(Lesson, params)
  end

  def perform
    unit = Unit.find_by_toc_location( request['unit_toc_location'] )
    raise "No unit found wtih toc_location '#{request['unit_toc_location']}'" if unit.nil?
    request.delete('unit_toc_location')
    request['unit_id'] = unit.id
    super
  end
  private :perform

  def object_to_publish
    return @object_to_publish if defined?(@object_to_publish)
    @object_to_publish = model_to_publish.find_by_unit_id_and_rank(request['unit_id'], request['rank'])
  end
end
