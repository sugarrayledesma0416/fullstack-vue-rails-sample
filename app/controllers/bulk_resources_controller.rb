class BulkResourcesController < ApplicationController
  before_action :require_user
  before_action :set_page_header
  before_action :validate_role
  before_action :set_current_program, except: %i[index select_program]
  include BulkUploadIrs
  include Uploadable::Controller

  def bulk_upload
    @signed_url = generate_presigned_url
  end

  def index
    @programs = Program.where(is_archived: false).order(:title)
  end

  def select_program
    selected_program = Program.find_by(id: select_program_params[:program_id])
    if selected_program
      redirect_to upload_bulk_resources_uploader_path(selected_program.id)
    else
      redirect_back fallback_location: root_path, alert: 'Program not found.'
    end
  end

  def validate
    resources_creator = BulkResourcesUploader::BulkResourcesCreator.new(@current_program)
    if resources_creator.zip_exist_in_s3? && resources_creator.csv_exist_in_s3?
      render json: resources_creator.validate_bulk_process
    else
      render json: { error_message: 'missing files', status: :bad_request }
    end
  end

  def files_s3_status
    resources_creator = BulkResourcesUploader::BulkResourcesCreator.new(@current_program)
    render json: resources_creator.files_status
  end

  def upload_csv
    file_data = upload_csv_params[:content]
    tracker = setup_tracker(@current_program.id, processing_files: true)
    tracker.update(csv_file_name: upload_csv_params[:csv_file_name])
    file_uploaded = s3_bucket
                    .store_file_contents("#{bulk_resources_path}/#{@current_program.id}" \
                                         "/#{@current_program.id}_m3_resources.csv", file_data)
    render json: { file_uploaded: }
  rescue ActionController::ParameterMissing => e
    render json: { error: e.message }, status: :bad_request
  end

  def bulk_delete
    @current_program.resources.each do |resource|
      resource.dispose_file(resource.file_path)
      resource.destroy!
    end
  end

  def creation_in_progress_status
    tracker = BulkResourcesCreationTracker.find_by(program_id: @current_program.id)
    if tracker.present?
      render json: BulkResourcesCreationTrackerSerializer.new(tracker)
    else
      render json: { creation_in_progress: false, state: '', logs: [], progress: 0 }
    end
  end

  # Spawns a worker to unzip the file provided by the user on S3 and create the Resource records.
  def start_creation
    program_id = @current_program.id
    BulkResourcesCreatorWorker.perform_async('program_id' => program_id)
    setup_tracker(program_id)
  end

  def download_errors_report
    resources_creator = BulkResourcesUploader::BulkResourcesCreator.new(@current_program)
    if resources_creator.errors_report_exist_in_s3?
      fetch_errors_report_from_bucket(resources_creator.csv_errors_report)
    else
      render json: { error_message: 'report not available', status: :bad_request }
    end
  end

  private def set_page_header
    @page_header = 'Bulk resources upload'
  end

  private def upload_csv_params
    params.require(:csv).permit(:content, :csv_file_name)
  end

  private def select_program_params
    params.permit(:program_id)
  end

  private def validate_role
    authorize! :bulk_upload, BulkResourcesController
  end
end
