class A11yReportGeneratorWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(program_id, include_details)
    report_generator = A11yReportGenerator.new(program_id, include_details)
    report_generator.generate_report
    report_generator.upload_report
    report_generator.delete_file
  end
end
