module Lti
  class HomePageDeepLinkJwt < BaseDeepLinkJwt
    attr_accessor :launch_guid

    def initialize(launch_guid)
      self.launch_guid = launch_guid
    end

    def to_h
      with_lti_event_tracking(
        'Create Home Page Deep Link',
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
      { view: 'homepage' }
    end

    private def content_title
      'VHLCentral Home'
    end
  end
end
