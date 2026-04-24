class UnitPublishProcessor
  include BasePublishProcessor

  VALID_ATTRIBUTES = %i[
    chinese_title
    english_title
    label
    media_item_id
    name
    pinyin_title
    program_id
    rank
    released
    resources_form_title
    toc_location
    use_type
  ].freeze

  REQUIRED_ATTRIBUTES = %i[program_id toc_location].freeze

  def initialize(params)
    super(Unit, params)
  end

  def object_to_publish
    return @object_to_publish if defined?(@object_to_publish)

    @object_to_publish = model_to_publish.find_by(
      program_id: request['program_id'],
      toc_location: request['toc_location']
    )
  end
end
