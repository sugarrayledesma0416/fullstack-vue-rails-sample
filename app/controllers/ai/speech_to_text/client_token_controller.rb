module AI
  module SpeechToText
    class ClientTokenController < ApplicationController
      include UnleashContextSetup

      PROVIDER_AUTO = 'auto'.freeze
      PROVIDER_AZURE = 'azure'.freeze
      PROVIDER_ANDROMEDA = 'andromeda'.freeze
      FEATURE_FLAG_SPEECH_REC_UPGRADE = 'MAE-Q4-2025-Speech-Rec-Upgrade'.freeze

      before_action :require_user

      def new
        # Get the requested provider from params
        requested_provider = params[:provider]

        # Only use determine_preferred_provider when the requested provider is 'auto'
        provider = if requested_provider == PROVIDER_AUTO
                     determine_preferred_provider
                   else
                     requested_provider == PROVIDER_AZURE ? PROVIDER_AZURE : PROVIDER_ANDROMEDA
                   end

        response_data = { provider: provider }

        # Only fetch an Azure token if we're going to use Azure
        if provider == PROVIDER_AZURE
          token = AI::AzureClient.new.scoped_token

          if token
            # Add token data to the response
            response_data.merge!(token.slice(:token, :expires_in))
            render json: response_data
          else
            # If token fetch failed but we need Azure, return an error
            head :forbidden
          end
        else
          # For Andromeda, just return the provider info without a token
          render json: response_data
        end
      end

      private def determine_preferred_provider
        # The Unleash context is set by the UnleashContextSetup concern
        # Use the Unleash feature flag to determine the provider
        if defined?(UNLEASH) &&
           UNLEASH.is_enabled?(FEATURE_FLAG_SPEECH_REC_UPGRADE, @unleash_context)
          PROVIDER_AZURE
        else
          PROVIDER_ANDROMEDA
        end
      end
    end
  end
end
