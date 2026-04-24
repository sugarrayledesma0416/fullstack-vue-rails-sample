module Etl
  module GradebookImport
    module Lti
      class ContextLink < Base
        def model_attr_names
          %w[
            context_id
            context_label
            context_title
            deployment_id
            id
            guid
            line_items_url
            lti_platform_id
            platform_type
            section_id
          ] + common_fields
        end
      end
    end
  end
end
