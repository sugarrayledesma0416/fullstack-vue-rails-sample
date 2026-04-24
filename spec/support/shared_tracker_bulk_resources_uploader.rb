RSpec.shared_context 'when tracker is created' do
  let(:tracker) { create(:bulk_resources_creation_tracker, program_id: program_id) }
  let(:custom_csv_file_name) { 'custom_errors_report.csv' }
end
