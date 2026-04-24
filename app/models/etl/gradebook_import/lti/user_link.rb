module Etl
  module GradebookImport
    module Lti
      class UserLink < Base
        def model_attr_names
          %w[
            id
            guid
            lti_platform_id
            platform_user_id
            user_id
          ] + common_fields
        end
      end
    end
  end
end
