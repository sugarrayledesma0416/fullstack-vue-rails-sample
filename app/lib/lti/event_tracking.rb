module Lti
  module EventTracking
    COMMON_DATA = {
      application: :m3,
      environment: Rails.env,
      vhl_component: :lti
    }.freeze

    def with_lti_event_tracking(message, data = {})
      event = Event.new(data)
      result = yield event if block_given?
      payload = event.payload
      result
    rescue StandardError => e
      error = lti_error_data(e)
      raise e
    ensure
      lti_event_dispatch(message, payload || {}, error || {})
    end
    alias track_lti_event with_lti_event_tracking

    private def lti_event_dispatch(message, payload, error)
      STATS_PROXY.info(
        COMMON_DATA.merge(event_action: message).merge(payload).merge(error)
      )
    end

    private def lti_error_data(error)
      {
        error_class: error.class,
        error_message: error.message,
        error_location: error.backtrace.first
      }
    end

    class Event
      attr_accessor :context_link, :extra, :launch, :params,
                    :session, :user_link
      attr_writer :platform, :section, :user

      def initialize(data)
        self.context_link = data[:context_link]
        self.extra = data[:extra] || {}
        self.launch = data[:launch]
        self.params = data[:params] || {}
        self.platform = data[:platform]
        self.section = data[:section]
        self.session = data[:session] || {}
        self.user = data[:user]
        self.user_link = data[:user_link]
      end

      def payload
        index_data.merge(
          context_link: context_link_data,
          extra: extra,
          launch: launch_data,
          params: params,
          platform: platform_data,
          section: section_data,
          session: session,
          user: user_data,
          user_link: user_link_data
        )
      end

      private def index_data
        {
          context_id: context_id,
          context_link_guid: context_link&.guid,
          launch_guid: launch_guid,
          platform_guid: platform_guid,
          platform_user_id: platform_user_id,
          section_guid: section&.guid,
          user_guid: user&.guid
        }
      end

      private def context_id
        context_link&.context_id
      end

      private def launch_guid
        launch&.guid || session[:lti_deep_link_launch_guid]
      end

      private def platform_guid
        platform&.guid
      end

      private def platform_user_id
        launch&.platform_user_id
      end

      private def context_link_data
        extract_attrs(
          context_link,
          :context_id, :context_label, :context_title, :deployment_id, :guid
        )
      end

      private def launch_data
        extract_attrs(launch, :guid)
      end

      private def platform
        @platform ||= context_link&.lti_platform || launch&.platform
      end

      private def platform_data
        extract_attrs(platform, :guid, :issuer_id, :name)
      end

      private def section
        @section ||= context_link&.section
      end

      private def section_data
        return {} unless section

        course = section.course
        {
          course_guid: course&.guid,
          guid: section.guid,
          name: section.name,
          program_id: course&.program_id
        }
      end

      private def user
        @user ||= user_link&.user
      end

      private def user_data
        extract_attrs(user, :account_type, :guid)
      end

      private def user_link_data
        extract_attrs(user_link, :guid, :platform_user_id)
      end

      private def extract_attrs(object, *attrs)
        return {} unless object

        object.attributes.symbolize_keys.slice(*attrs)
      end
    end
  end
end
