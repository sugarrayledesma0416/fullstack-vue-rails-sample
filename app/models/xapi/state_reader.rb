module Xapi
  class StateReader
    include State

    def initialize(params)
      @params = params
    end

    def record_exists?
      activity_state.present?
    end

    def serialize
      {
        suspend: activity_state.payload,
        location: activity_state.page_location,
        totalTime: activity_state.milliseconds_spent
      }
    end

    private def activity_state
      return @activity_state if defined? @activity_state
      @activity_state = attempt ? existing_activity_state : nil
    end
  end
end
