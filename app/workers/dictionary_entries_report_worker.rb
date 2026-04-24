class DictionaryEntriesReportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false
  queue_as :default

  def perform(program_id, cms_activity_ids)
    reporter = DictionaryEntriesExport::DictionaryEntriesReport.new(program_id:, cms_activity_ids:)
    reporter.generate_csv_file
    reporter.upload_csv_file
    reporter.delete_temp_csv_file
    reporter.errors_export if reporter.errors.any?
  end
end
