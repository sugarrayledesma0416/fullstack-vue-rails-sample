module Dangerfield
  class SchoolConfigSerializer < Dangerfield::BaseSerializer
    exclude_attributes %i[school_id web_token institute_short_name]
  end
end
