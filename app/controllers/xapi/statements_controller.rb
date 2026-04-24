module Xapi
  class StatementsController < ApplicationController
    include BasicAuthentication

    skip_before_action :verify_authenticity_token
    before_action :authenticate_xapi

    def update
      successful_write = StatementWriter.new(statement_params_hash).write
      head successful_write ? :no_content : :conflict
    end

    private def statement_params_hash
      params.permit(
        :id,
        :timestamp,
        actor: %i[mbox name objectType],
        context: {},
        object: {},
        result: {},
        verb: {}
      ).tap do |memo|
        # After Rails 5.1, this tap can be removed, as the empty-hash
        # syntax used above is introduced.
        %i[context object result verb].each do |key|
          memo[key] = params[key].permit! if params.key?(key)
        end
      end.to_h.with_indifferent_access
    end
  end
end
