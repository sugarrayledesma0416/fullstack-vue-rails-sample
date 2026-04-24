class DictionaryEntriesController < ApplicationController
  def generate_report
    reporter = DictionaryEntriesExport::DictionaryEntriesReport.new(program_id:, cms_activity_ids:)
    errors = reporter.pre_process_validation
    if errors.any?
      render json: { error_message: errors.join(', ') }, status: :bad_request
    else
      message = 'The CSV generation process has started. This may take several minutes.'
      DictionaryEntriesReportWorker.perform_async(program_id, cms_activity_ids)
      render json: { message: }, status: :accepted
    end
  end

  def download_csv
    response = csv_download_url
    if response[:success]
      render json: { signed_url: response[:body]['signed_url'],
                     found_errors: response[:body]['found_errors'] }
    else
      error_message = response[:body]['error_message'] || 'The file is not available yet.'
      render json: { error_message: }, status: :not_found
    end
  end

  private def csv_download_url
    reporter = DictionaryEntriesExport::DictionaryEntriesReport.new(program_id:, cms_activity_ids:)
    if reporter.csv_exists_in_s3?
      { success: true, body: { 'signed_url' => reporter.signed_url,
                               'found_errors' => reporter.found_errors? } }
    else
      { success: false, body: { 'error_message' => 'The file is not available yet.' } }
    end
  end

  private def program_id
    params[:program_id]
  end

  private def cms_activity_ids
    params[:cms_activity_ids]
  end
end
