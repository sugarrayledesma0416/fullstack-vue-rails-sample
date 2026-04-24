module Lti
  class DeepLinkSessionsController < RequireInstructorController
    layout 'music_v1/minimal'

    def init
      section = Section.find_by!(guid: params[:section_guid])
      @launch = Lti::Launch.find_by!(guid: params[:launch_guid])

      # Is it worth validating the deep-linking settings in the launch data
      # at this point? We can assume that UA isn't sending us here unless
      # it detected that the launch message type is an LtiDeepLinkingRequest,
      # but there may be invalid values in the deep_link_settings claim.

      # Could also validate the existence of an Lti::ContextLink record where
      # the context_id matches the launch data and section matches the
      # specified section.

      session[:lti_deep_link_launch_guid] = @launch.guid
      session[:lti_launch_expiration] = 1.hour.from_now.to_i

      # This existing method from FocusAssignment module was originally
      # defined with a slightly-too-specific name, but it does exactly
      # what's needed here.
      set_focus_after_creation(section.course, section: section)
    end

    def terminate
      session[:lti_deep_link_launch_guid] = nil
      session[:lti_launch_expiration] = 1.second.ago.to_i

      redirect_to vhl_return_to_sanitizer(params[:return_to])
    end
  end
end
