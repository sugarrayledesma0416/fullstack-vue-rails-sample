describe A11yReportGenerator do
  let(:program) { create(:program, id: 777) }
  let(:include_details) { true }
  let(:local_filename) { "/tmp/a11y_report_program_#{program.id}_#{timestamp}.xlsx" }
  let(:current_date) { Time.current }
  let(:timestamp) { current_date.utc.strftime('%FT%T') }
  let(:report_tool) { described_class.new(program.id, include_details) }
  let(:spreadsheet) { A11ySpreadsheet.new(program.id, true) }
  let(:row_data) do
    [{ 'Lesson' => 'Lección 18 | Lección de ejemplo',
       'Strand' => 'Multi-Lesson Exam',
       'Title' => 'Lecciones 13-18, Examen B',
       'Rating' => 'Accessible',
       'Link' => 'example-link.com',
       'Type' => 'exam',
       'IssueList' => '{}',
       'SubActivityTypes' => '' }]
  end

  let(:signed_url) { 'signed_report_url' }

  let(:s3_bucket) do
    instance_double(
      Radner::S3Storage,
      file_exist?: true,
      upload_error: nil,
      upload_file: true
    )
  end

  let(:s3_listing_for_simplified_report) do
    [
      OpenStruct.new(
        bucket_name: 'files.dev.vhlcentral.com',
        key: "tasks/a11y_reports/simplified_reports/simplified_a11y_report_program_#{program.id}_#{timestamp}.xlsx",
        last_modified: current_date + 3.minutes
      )
    ]
  end

  let(:s3_listing_for_detailed_report) do
    [
      OpenStruct.new(
        bucket_name: 'files.dev.vhlcentral.com',
        key: "tasks/a11y_reports/detailed_reports/detailed_a11y_report_program_#{program.id}_#{timestamp}.xlsx",
        last_modified: current_date + 5.minutes
      )
    ]
  end

  let(:object) { instance_double(Aws::S3::Object, last_modified: current_date) }
  let(:bucket) { instance_double(Aws::S3::Bucket, object: object) }

  before do
    allow(Aws::CF::Signer).to receive(:sign_url).and_return(signed_url)
    allow(report_tool).to receive(:s3_bucket).and_return(s3_bucket)
    allow(s3_bucket).to receive(:bucket).and_return(bucket)
    allow(A11ySpreadsheet).to receive(:new).with(program.id, true).and_return(spreadsheet)
    allow(spreadsheet).to receive(:data).and_return(row_data)
    allow(s3_bucket).to receive(:directory_files)
      .with(described_class::S3_DESTINATION_FOLDER['simplified'])
      .and_return(s3_listing_for_simplified_report)
    allow(s3_bucket).to receive(:directory_files)
      .with(described_class::S3_DESTINATION_FOLDER['detailed'])
      .and_return(s3_listing_for_detailed_report)
    # clean up spreadsheet file in /tmp
    @recycle_bin << local_filename
  end

  around(:example) do |example|
    Timecop.freeze(&example)
  end

  describe '#generate_report' do
    it 'generates a .xlsx file with the accesibility report' do
      report_tool.generate_report

      expect(File).to exist(local_filename)
    end
  end

  describe '#upload_report' do
    it 'uploads the report to s3' do
      s3_path = report_tool.file_s3_path
      report_tool.generate_report
      report_tool.upload_report
      expect(s3_bucket).to have_received(:upload_file)
        .with(s3_path, local_filename)
    end
  end

  describe '#delete_file' do
    it 'deletes the file generated' do
      report_tool.generate_report
      report_tool.delete_file
      expect(File).not_to exist(local_filename)
    end
  end

  describe '#simplified_report_url' do
    it 'returns the signed url of the simplified report' do
      simplified_report = report_tool.simplified_report_url
      expect(simplified_report).to eq(signed_url)
    end
  end

  describe '#detailed_report_url' do
    it 'returns the signed url of the detailed report' do
      simplified_report = report_tool.detailed_report_url
      expect(simplified_report).to eq(signed_url)
    end
  end

  describe '#simplified_report_last_modified' do
    it 'returns the date of the last upload of the simplified report' do
      expected_last_modified = (current_date + 3.minutes).to_s(:rfc822)
      last_modified = report_tool.simplified_report_last_modified
      expect(last_modified).to eq(expected_last_modified)
    end
  end

  describe '#detailed_report_last_modified' do
    it 'returns the date of the last upload of the detailed report' do
      expected_last_modified = (current_date + 5.minutes).to_s(:rfc822)
      last_modified = report_tool.detailed_report_last_modified
      expect(last_modified).to eq(expected_last_modified)
    end
  end
end
