module Xapi
  class StateWriter
    include State

    def initialize(params)
      @params = params
    end

    def update
      return unless state_modifiable?
      activity_state.update!(
        denormalized_attempt_attrs.merge(
          payload: payload,
          page_location: page_location,
          milliseconds_spent: milliseconds_spent
        )
      )
    end

    private def activity_state
      @activity_state ||= existing_activity_state || ActivityState.new(
        id: state_id
      )
    end

    private def denormalized_attempt_attrs
      attempt.attributes.symbolize_keys.slice(:activity_id, :section_id, :user_id)
    end

    private def payload
      @params[:state][:suspend]
    end

    private def page_location
      @params[:state][:location]
    end

    private def milliseconds_spent
      @params[:state][:totalTime]
    end
  end
end
