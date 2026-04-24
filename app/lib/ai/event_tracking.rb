module AI
  module EventTracking
    COMMON_DATA = {
      application: :m3,
      environment: Rails.env,
      vhl_component: :ai_grading
    }.freeze

    def with_ai_grading_event_tracking(message, data = {})
      event = Event.new(data)
      result = yield event if block_given?
      payload = event.payload
      result
    rescue StandardError => e
      error = ai_error_data(e)
      raise e
    ensure
      ai_event_dispatch(message, payload || {}, error || {})
    end
    alias track_ai_grading_event with_ai_grading_event_tracking

    private def ai_event_dispatch(message, payload, error)
      STATS_PROXY.info(
        COMMON_DATA.merge(event_action: message).merge(payload).merge(error)
      )
    end

    private def ai_error_data(error)
      {
        error_class: error.class,
        error_message: error.message,
        error_location: error.backtrace.first
      }
    end

    class Event
      attr_accessor :extra, :params, :user, :section, :session

      def initialize(data)
        self.extra = data[:extra] || {}
        self.params = data[:params] || {}
        self.section = data[:section]
        self.session = data[:session] || {}
        self.user = data[:user]
      end

      def payload
        index_data.merge(
          extra:,
          params:,
          section: section_data,
          session:,
          user: user_data
        )
      end

      private def index_data
        {
          section_guid: section&.guid,
          user_guid: user&.guid
        }
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

      private def user_data
        extract_attrs(user, :account_type, :guid)
      end

      private def extract_attrs(object, *attrs)
        return {} unless object

        object.attributes.symbolize_keys.slice(*attrs)
      end
    end
  end
end
