class VocabToolsUnitsPresenter
  attr_accessor :section, :program

  def initialize(section, program)
    self.section = section
    self.program = program
  end

  def payload
    {
      units: units,
      enrolled: !section.course.nil?,
      language_name: program.language_name
    }
  end

  def units
    program.units.sort_by(&:rank).map do |unit|
      unit_dup = unit.dup
      unit_dup.id = unit.id
      UnitSerializer.new(unit_dup).as_json(section: section,
                                           two_tier: program.two_tier?)
    end
  end
  private :units
end
