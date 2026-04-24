class InstructorResourcesExportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(program_id, export_type = 'zip')
    program = Program.find(program_id)
    exporter = InstructorResourcesExport.new(program)

    case export_type
    when 'zip'
      exporter.fetch_and_zip_resources
      exporter.delete_files
    when 'csv'
      exporter.export_resources_to_csv
      exporter.upload_csv_file
      exporter.delete_files
    end
  end
end
