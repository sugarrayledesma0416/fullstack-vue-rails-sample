require 'json/jwt'

module Lti
  module TocDeepLinking
    def lti_deep_link_enabled?
      launch && !launch_expired?
    end

    def lti_deep_link_return_url
      launch&.deep_link_return_url
    end

    def launch_guid
      session[:lti_deep_link_launch_guid]
    end

    # :nocov:
    def session
      if defined?(super)
        super
      else
        raise(
          NotImplementedError,
          "Presenters including #{method(__method__).owner} must define #{__method__}"
        )
      end
    end
    # :nocov:

    private def launch
      return @launch if defined?(@launch)

      @launch = launch_guid && Launch.find_by(guid: launch_guid)
    end

    private def launch_expired?
      launch_expiration.blank? || Time.at(launch_expiration).utc < Time.now.utc
    end

    private def launch_expiration
      session[:lti_launch_expiration]
    end
  end
end
