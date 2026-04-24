module Standards
  class AssetsController < ApplicationController
    include HttpBasicAuthHelper
    include StandardsAssets

    before_action :http_basic_authenticate
    skip_before_action :verify_authenticity_token

    def create
      respond_to do |format|
        format.json do
          begin
            create_asset
          rescue ActiveRecord::RecordInvalid => e
            return render json: { error: validation_errors(e) }, status: :unprocessable_entity
          end
          render json: { asset: @asset }, status: :created
        end
      end
    end

    def update
      respond_to do |format|
        format.json do
          begin
            update_asset
          rescue ActiveRecord::RecordNotFound => e
            return render json: { error: e.message }, status: :not_found
          rescue ActiveRecord::RecordInvalid => e
            return render json: { error: validation_errors(e) }, status: :unprocessable_entity
          end
          render json: { asset: @asset }, status: :ok
        end
      end
    end
  end
end
