class ConceptPublishProcessor
  include BasePublishProcessor

  VALID_ATTRIBUTES = %i[
    assessment
    background_color
    base_name
    breadcrumb_string
    id
    lesson_id
    media_item_id
    name
    program_id
    rank
    singular_label
  ].freeze

  REQUIRED_ATTRIBUTES = %i[
    id
    lesson_rank
    name
    program_id
    rank
    unit_toc_location
  ].freeze

  def initialize(params)
    super(Concept, params)
  end

  private def perform
    unit = Unit.find_by_toc_location( request['unit_toc_location'] )
    raise "No unit found with toc_location '#{request['unit_toc_location']}'" unless unit

    lesson = Lesson.find_by_unit_id_and_rank(unit.id, request['lesson_rank'])
    raise "No lesson found with unit_id '#{unit.id}' and lesson_rank '#{request['lesson_rank']}'" unless lesson

    request.delete('unit_toc_location')
    request['lesson_id'] = lesson.id
    super
  end
end
