module Lti
  class ActivityDeepLinkJwt < BaseDeepLinkJwt
    attr_accessor :activity_id, :launch_guid

    def initialize(activity_id, launch_guid)
      self.activity_id = activity_id.to_i
      self.launch_guid = launch_guid
    end

    def to_h
      with_lti_event_tracking(
        'Create Activity Deep Link',
        extra: payload,
        launch: launch
      ) do
        { jwt: token, link_info: content_title }
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

    private def activity
      @activity ||= Activity.find(activity_id)
    end

    private def content_ids
      {
        activity_id: activity_id,
        program_id: activity.program.id
      }
    end

    private def content_title
      @content_title ||= [
        activity.lesson_display_name,
        activity.strand.display_name,
        activity.title
      ].compact.join(' - ').strip_tags.html_decode
    end
  end
end
