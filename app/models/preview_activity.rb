class PreviewActivity < Activity
  after_initialize :readonly!

  REQUIRED_PARAMS = %i[
    activity_type
    cms_revision_id
    concept_id
    content
    lesson_id
    toc_location
  ].freeze

  delegate :has_rubric?, :submittable?, to: :content_object

  def initialize(opts = {})
    check_params(opts)
    @lesson_id = opts[:lesson_id]
    super
  end

  # :nocov:
  # the activity form needs an id to generate the submit path
  def id
    @id ||= rand(10_000)
  end
  # :nocov:

  # :nocov:
  # these 2 methods disable composition upload
  def composition?
    false
  end
  # :nocov:

  # :nocov:
  def has_composition_activities?
    false
  end
  # :nocov:

  # used as control logic in the erbs
  def preview?
    true
  end

  def program
    return @program if defined? @program

    @program = Lesson.find(@lesson_id).program
  end

  private def check_params(opts)
    missing_keys = if opts.blank?
                     REQUIRED_PARAMS
                   else
                     REQUIRED_PARAMS - opts.keys
                   end

    raise ArgumentError, "#{missing_keys.join(', ')} required!" if missing_keys.present?
  end
end
