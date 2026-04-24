class ProgramConfigPresenter
  attr_accessor :program_config

  def initialize(program_config)
    self.program_config = program_config
  end

  def standard_sets
    sets = StandardSet.select(:id, :display_name)
                      .where.not(display_name: [nil, ''])
                      .group_by(&:display_name)
                      .map do |display_name, id|
      {
        name: display_name,
        ids: id.map(&:id).join(',')
      }
    end

    sets.sort_by { |set| set[:name] }
  end
end
