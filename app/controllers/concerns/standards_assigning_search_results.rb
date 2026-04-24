module StandardsAssigningSearchResults
  extend ActiveSupport::Concern

  def matched_standards
    begin
      params.require(%i[standard_set_vendor_guid search_term])
    rescue ActionController::ParameterMissing
      return render json: {}, status: :bad_request
    end

    begin
      payload = @presenter.matching_standards
    rescue StandardError => e
      Rollbar.error(e, e.message)
      return render json: { error_message: e.message }, status: :internal_server_error
    end

    render json: { matched_standards: payload }, status: :ok
  end

  def preload_standards_filter
    begin
      params.require(%i[program_id])
    rescue ActionController::ParameterMissing
      return render json: {}, status: :bad_request
    end

    begin
      @preload_standards_filter = @presenter.preload_standards_filter
    rescue StandardError => e
      Rollbar.error(e, e.message)
      return render json: { error_message: e.message }, status: :internal_server_error
    end
  end

  def matched_assets_with_standards
    return render json: {}, status: :bad_request unless any_matched_assets_params_present?

    begin
      payload = @presenter.assets_and_standards_payload
    rescue StandardError => e
      Rollbar.error(e, e.message)
      return render json: { error_message: e.message }, status: :internal_server_error
    end

    render json: { assets_and_standards: payload }, status: :ok
  end

  def matched_standards_for_browse
    begin
      params.require(%i[standard_set_vendor_guid])
    rescue ActionController::ParameterMissing
      return render json: {}, status: :bad_request
    end

    begin
      payload = @presenter.browse_standards
    rescue StandardError => e
      Rollbar.error(e, e.message)
      return render json: { error_message: e.message }, status: :internal_server_error
    end

    render json: { matched_browse_standards: payload }, status: :ok
  end

  private def any_matched_assets_params_present?
    %i[selected_refinements selected_skills selected_standards].any? do |param_key|
      params[param_key].present?
    end
  end
end
