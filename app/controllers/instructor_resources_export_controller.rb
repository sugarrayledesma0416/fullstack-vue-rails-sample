# Controller for Instructor Resources Exporting Tool located in "Tech Production Tools"
class InstructorResourcesExportController < ApplicationController
  before_action :require_user
  before_action :validate_role

  def index
    @programs = Program.where(is_archived: false).order(:title)
  end

  def export
    exporter = InstructorResourcesExport.new(program)
    exporter.set_file_path_to_zip

    return unless exporter.zip_exist_in_s3?

    @file_size = exporter.formatted_file_size
    @download_link = exporter.signed_url
    @last_modified = exporter.last_modified
  end

  def generate_new_link
    InstructorResourcesExportWorker.perform_async(program.id)
  end

  def export_csv
    exporter = InstructorResourcesExport.new(program)
    exporter.set_file_path_to_csv
    InstructorResourcesExportWorker.perform_async(program.id, 'csv')
    wait_for_csv_file(exporter, _max_retries = 5)
    if exporter.csv_exists_in_s3?
      redirect_to exporter.signed_url
    else
      flash[:error] = 'The requested CSV file could not be generated. Please try again later.'
      redirect_to index_instructor_resources_export_path
    end
  end

  def program
    @program = Program.find(params[:program_id])
  end

  private def wait_for_csv_file(exporter, max_retries = 5)
    retry_count = 0
    until exporter.csv_exists_in_s3? || retry_count >= max_retries
      exporter.export_resources_to_csv
      exporter.upload_csv_file
      retry_count += 1
    end
  end

  private def validate_role
    authorize! :export, InstructorResourcesExportController
  end
end
