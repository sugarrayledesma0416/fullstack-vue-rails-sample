module Lti
  class ResourceLinksController < ApplicationController
    before_action :require_user

    def show
      ensure_sufficient_access
      redirect_to(
        ResourceLinkRedirect.new(params, current_section_id, current_user).url
      )
    end

    private def ensure_sufficient_access
      return if params['section_guid'].blank? || current_user.instructor?

      section = Section.find_by(guid: params['section_guid'])
      ActiveEnrollmentAccessUpdater.new(current_user, section).update if section
    end
  end
end
