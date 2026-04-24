module Xapi
  VERB_ANSWERED = 'http://adlnet.gov/expapi/verbs/answered'.freeze
  VERB_INITIALIZED = 'http://adlnet.gov/expapi/verbs/initialized'.freeze
  VERB_TERMINATED = 'http://adlnet.gov/expapi/verbs/terminated'.freeze
  VERB_EXPERIENCED = 'http://adlnet.gov/expapi/verbs/experienced'.freeze
  VERB_ATTEMPTED = 'http://adlnet.gov/expapi/verbs/attempted'.freeze

  def self.table_name_prefix
    'xapi_'
  end
end
