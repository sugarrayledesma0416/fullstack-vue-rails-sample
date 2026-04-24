class StandardAlignmentsController < ApplicationController
  include HttpBasicAuthHelper
  include UpdateStandardAlignments
  include WorkerCheck

  before_action :http_basic_authenticate

  # endpoint called from CMS to do the following:
  #  - trigger sidekiq worker to call AcademicBenchmarks API
  #    to retrieve new/modified/deleted standard_asset alignments
  #  - upload new and updated StandardAssets and their alignments to OpenSearch
  #    standard_alignments index
  # Params:
  #   - program_id: required, the ID of the program to update
  #   - import_type: optional, the type of import to perform
  def update
    Rails.logger.info(
      '[StandardAlignmentsController] update - Received request to update ' \
      "standard alignments with params: #{params}"
    )

    worker_class = StandardAlignmentsUpdateWorker

    if conflicting_process_running?(worker_class)
      Rails.logger.info(
        '[StandardAlignmentsController] update - Request rejected: ' \
        "#{worker_class} already running"
      )
      render json: {
        message: 'Your request could not be processed because a Standard ' \
                 'Alignments update is already in progress. Please wait ' \
                 'until the current update is complete before trying again.'
      }, status: :conflict
      return
    end

    worker_class.perform_async(required_params.stringify_keys)
    render json: {
      message: 'Standard Alignments undergoing update in M3 and OpenSearch'
    }, status: :ok
  end

  private def required_params
    {
      program_id: params.require(:program_id),
      import_type: params[:import_type]
    }.compact
  end
end
