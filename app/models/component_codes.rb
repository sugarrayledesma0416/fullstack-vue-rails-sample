class ComponentCodes
  attr_accessor :program_id

  def initialize(program_id)
    self.program_id = program_id
  end

  def components
    return @components if defined?(@components)
    components =
      Activity
      .joins(lesson: :unit)
      .where(units: { program_id: program_id })
      .where(activities: { instructor_revision_id: nil })
      .where('activities.toc_location IS NOT NULL')
      .pluck('component_name')
    @components = components.map(&:strip).uniq
  end
  alias_method :labels, :components
end
