module BulkUploadIrs
  include Radner::FilesS3Bucket

  # This method provides the presigned URL used to upload the zip file to our S3 via
  # a POST request, along with a list of fields that must be included in the request.
  def generate_presigned_url
    file_name = "#{@current_program.id}_m3_resources.zip"
    key = "#{bulk_resources_path}/#{@current_program.id}/#{file_name}"
    post = s3_bucket.bucket.presigned_post(
      key:,
      acl: 'private',
      content_type: 'application/zip',
      expires: 1.hour.from_now
    )
    { url: post.url, fields: post.fields }.to_json
  end

  # Provides the root path on S3 used to store the zip file and the other files involved
  # in the bulk creation process. This is particularly relevant for QA environments.
  def bulk_resources_path
    env = M3::Application.config.current_deployed_env_name
    "admin_tasks/bulk_irs/#{env}"
  end

  def fetch_errors_report_from_bucket(csv_errors_report)
    csv = s3_bucket.fetch(csv_errors_report)
    render json: { csv: }
  end

  def setup_tracker(program_id, processing_files: false)
    tracker = BulkResourcesCreationTracker.find_or_initialize_by(program_id:)
    tracker.logs = { data: [] }.to_json

    tracker.reset! if tracker.persisted? && tracker.may_reset? && !processing_files
    tracker.processing_files! if processing_files && tracker.may_processing_files?
    tracker.save!
    tracker
  end
end
