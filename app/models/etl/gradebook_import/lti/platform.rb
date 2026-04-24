module Etl
  module GradebookImport
    module Lti
      class Platform < Base
        def model_attr_names
          %w[
            authorization_services_id
            client_id
            disabled
            guid
            id
            issuer_id
            keyset_url
            lms_type
            name
            oauth2_url
            oidc_auth_url
            service_type
          ] + common_fields
        end
      end
    end
  end
end
