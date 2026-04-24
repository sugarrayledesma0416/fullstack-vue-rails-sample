class RecordDestination
  def initialize
  end

  def write(record)
    record.save
  end

  def close
  end
end

class Source
  def each
    @records.each do |record|
      yield record
    end
  end
end

class Transform
  def initialize(model)
    @model = model
  end

  def process(record)
    models_with_db_assigned_id = [GradebookEngine::ScoreAction, GradebookEngine::SectionUser, GradebookEngine::Assignment]
    if models_with_db_assigned_id.include?(@model) || @model.where(id: record.id).empty?
      new_record = @model.new
      new_record.attributes = record.attributes.slice(*@common_fields)
      if block_given?
        yield new_record
      end
      new_record
    end
  end
end
