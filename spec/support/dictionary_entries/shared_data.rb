RSpec.shared_context 'when the program contains the activities with supported activity_types' do
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson_with_unit, unit: unit) }
  let(:activities) do
    create_list(:activity, 2, lesson:) do |activity, i|
      activity.cms_activity_id = i + 1
      activity.activity_type = 'vocabulary_tutorial'
      activity.save!
    end
  end
  let(:report) { DictionaryEntriesExport::DictionaryEntriesReport.new(program_id:, cms_activity_ids:) }
end

RSpec.shared_context 'with dictionary entries report data' do
  let(:file_path) { "tasks/dictionary_entries_reports/#{file_name}" }
  let(:headers) { described_class::HEADERS }
  let(:temp_csv_file) { instance_double(Tempfile, path: "/tmp/#{file_name}") }
  let(:temp_file_path) { "/tmp/#{file_name}" }
  let(:csv) { instance_double(CSV) }
end

RSpec.shared_context 'when the program does not contain the activities' do
  let(:program_no_activities) { create(:program) }
  let(:report_no_activities) do
    DictionaryEntriesExport::DictionaryEntriesReport.new(
      program_id: program_no_activities.id,
      cms_activity_ids:
    )
  end
end

RSpec.shared_context 'with dictionary entries s3 data' do
  let(:s3_object) { instance_double(Aws::S3::Object, upload_file: true, exists?: true) }
  let(:s3_bucket) do
    instance_double(
      Radner::S3Storage,
      file_exist?: true,
      fetch: 'file_contents',
      upload_file: true,
      bucket: instance_double(
        Aws::S3::Bucket,
        object: s3_object
      )
    )
  end
end
