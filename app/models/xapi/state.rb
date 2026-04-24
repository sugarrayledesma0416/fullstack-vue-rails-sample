module Xapi
  module State
    include AttemptUserToken

    private def existing_activity_state
      ActivityState.find(
        id: state_id
      )
    end

    private def mbox
      JSON.parse(@params[:agent], symbolize_names: true)[:mbox]
    end

    private def learning_module_id
      @params[:activityId]
    end

    private def state_id
      # Rmq: We use attempt.id instead of user_token.attempt_id to raise an error
      # when no attempt exists.
      @state_id ||= "#{state_id_prefix}#{attempt.id}"
    end

    # Live servers use one dynamodb table.
    # All developers and all QA servers use the same dynamodb table so we
    # add a prefix to the hash key to avoid conflicts.
    private def state_id_prefix
      if Rails.env.live? || Rails.env.production?
        ''
      else
        "#{Rails.env}_#{Socket.gethostname}_"
      end
    end
  end
end
