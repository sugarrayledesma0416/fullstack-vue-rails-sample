module Xapi
  module AttemptUserToken
    private def attempt
      # Something is gone wrong if we don't have a attempt.
      # We can't just call Attempt.find because if it raises an ActiveRecord::RecordNotFound
      # error, the controller will translate into a 404.
      # However, in this particular case we want to return a 500 error.
      # That's why we raise an ArgumentError when the attempt does not exist.
      # The controller will take care of returning a 500 error.
      (@attempt ||= Attempt.where(id: user_token.attempt_id).first) ||
      raise(ArgumentError, 'invalid attempt_id')
    end

    private def user_token
      @user_token ||= XapiUserToken.new(mbox: mbox)
    end

    private def mbox
      raise NotImplementedError, 'classes or modules that include Xapi::AttemptUserToken ' \
        'must implement mbox method that returns a hash with symbols as keys.'
    end

    # for some cases we do not want to save the Xapi state;
    # caller decides the circumstances and encodes it in the mbox
    private def state_modifiable?
      user_token.attrs[:state_modifiable] == true
    end
  end
end
