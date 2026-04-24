class AssignmentWizardCopier
  extend LightService::Organizer

  ACTIONS = [
    FindCourse,
    ScheduleBulkAssignmentCreation,
    reduce_if(
      ->(context) { context[:source_section_id] && context[:copy_external_items?] },
      ScheduleExternalItemCopy
    )
  ].freeze

  # Set initial context for actions organized by the organizer
  def self.call(params, course_scope=nil)
    with(create_context(params, course_scope)).reduce(ACTIONS)
  end

  def self.create_context(params, course_scope)
    {
      categories_hash: safe_categories_hash(params),
      assignments_hash: safe_assignments_hash(params),
      course_id: course_id(params),
      destination_section_id: section_id(params),
      source_section_id: source_section_id(params),
      job_ids: [],
      copy_external_items?: copy_external_items?(params),
      course_scope: course_scope
    }
  end

  # Assignments and categories have unpredictable hash keys, but
  # the values are hashes with predictable keys that should be
  # whitelisted.
  def self.safe_assignments_hash(params)
    {}.tap do |memo|
      params[:raw_assignments].each_pair do |key, values|
        # Params may have an assignment date key with no assignments. These are
        # posted as an empty array, but Rack or Rails converts the empty array
        # to nil. Skip these pairs to avoid NoMethodError .map for NilClass.
        next if values.nil?

        memo[key] = values.map do |value|
          value.permit(:category, :due_date, :group_id, :id).to_h.with_indifferent_access
        end
      end
    end
  end

  def self.safe_categories_hash(params)
    {}.tap do |memo|
      params[:categories].each_pair do |key, value|
        memo[key] = value.permit(:id, :name).to_h.with_indifferent_access
      end
    end
  end

  def self.course_id(params)
    params.require(:course_id)
  end

  def self.section_id(params)
    params.require(:section_id)
  end

  def self.source_section_id(params)
    params[:source_section_id]
  end

  def self.copy_external_items?(params)
    params.key?(:copy_external_items?) ? params[:copy_external_items?] : false
  end
end
