module DataStorable
  def initialize(attempt)
    @attempt = attempt
  end

  def self.build(attempt, datastore_type = 'api')
    datastore_type == 'api' ? ResultsApiDatastore.new(attempt) : ResultsXmlDatastore.new(attempt)
  end
end
