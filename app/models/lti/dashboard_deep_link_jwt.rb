module Lti
  class DashboardDeepLinkJwt < BaseDeepLinkJwt
    attr_accessor :launch_guid, :program_id

    def initialize(program_id, launch_guid)
      self.program_id = program_id
      self.launch_guid = launch_guid
    end

    def to_h
      with_lti_event_tracking(
        'Create Dashboard Deep Link',
        extra: payload,
        launch: launch
      ) do
        { jwt: token }
      end
    end

    private def resource_link_data
      {
        custom: content_ids,
        title: content_title,
        type: 'ltiResourceLink',
        url: ua_lti_resource_link_url
      }
    end

    private def content_ids
      {
        program_id: program_id,
        view: 'dashboard'
      }
    end

    private def content_title
      'Current Assignments'
    end
  end
end
