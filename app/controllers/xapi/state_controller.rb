module Xapi
  class StateController < ApplicationController
    include BasicAuthentication

    skip_before_action :verify_authenticity_token
    before_action :authenticate_xapi

    STATE_NOT_FOUND_ERROR_MSG = 'Could not find state'.freeze

    def show
      state_reader = StateReader.new(params)
      if state_reader.record_exists?
        render json: state_reader.serialize.to_json
      else
        render plain: STATE_NOT_FOUND_ERROR_MSG, status: :not_found
      end
    end

    def update
      StateWriter.new(params).update
      head :no_content
    end
  end
end
