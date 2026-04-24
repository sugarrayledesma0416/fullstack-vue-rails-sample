require 'json/jwt'

module Lti
  class BaseDeepLinkJwt
    include EventTracking

    private def token
      JWT.encode(payload, tool_private_key, 'RS256', kid: key_id, typ: 'JWT')
    end

    private def launch
      @launch ||= Launch.find_by!(guid: launch_guid)
    end

    private def payload
      jwt_security_claims.merge(
        claims[:content_item] => [resource_link_data],
        claims[:deployment_id] => launch.deployment_id,
        claims[:lti_version] => '1.3.0',
        claims[:message_type] => 'LtiDeepLinkingResponse'
      )
    end

    private def jwt_security_claims
      {
        aud: launch.platform.issuer_id, # The platform is the intended audience
        exp: Time.now.to_i + 300, # Allow a margin for clock skew
        iat: Time.now.to_i, # Timestamp when JWT issued
        iss: launch.platform.client_id, # Unique id of JWT issuer
        jti: SecureRandom.hex(10), # Unique id for this token
        nonce: SecureRandom.hex(10) # Can guard against replay attacks
      }.merge(jwt_data_claim)
    end

    # If the launch jwt settings contain a data key, the exact value must be
    # returned under the data claim, otherwise no data claim key should be
    # sent.
    private def jwt_data_claim
      if launch.deep_link_data.present?
        { claims[:deep_linking_data] => launch.deep_link_data }
      else
        {}
      end
    end

    private def ua_lti_resource_link_url
      URI(UA_URL).tap do |uri|
        uri.path = '/lti/resource_link'
        uri.query = content_ids.to_query
      end.to_s
    end

    private def key_id
      tool_private_key.to_jwk['kid']
    end

    private def tool_private_key
      Rails.configuration.lti_tool_private_keys.first
    end

    # Since the claims and scopes are already defined in the gradebook engine,
    # use those definitions rather than repeating them.
    private def claims
      GradebookEngine::Lti::Constants::CLAIMS
    end

    # :nocov:
    private def current_host
      if defined?(UA_URL)
        UA_URL
      else
        'https://www.test.vhlcentral.com/'
      end
    end
    # :nocov:
  end
end
