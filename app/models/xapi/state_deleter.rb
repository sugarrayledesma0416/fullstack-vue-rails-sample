module Xapi
  class StateDeleter
    include State

    def initialize(attempt)
      @attempt = attempt
    end

    # when the attempt is reset we need to
    # remove the prior state that was
    # attached to that attempt
    # look it up and if found delete it
    def delete
      find_activity_state&.delete!
    end

    private def find_activity_state
      existing_activity_state
    end
  end
end
