ERRORS_SIZE = {
  'file_not_found' => 2,
  'invalid_characters' => 1,
  'empty_row' => 1,
  'missing_field' => 4,
  'unit_out_of_range' => 2,
  'numeric_column' => 1,
  'invalid_unit_format' => 1
}.freeze
ERRORS_BREAKDOWN_KEYS = %w[file_not_found invalid_characters invalid_unit_format
                           empty_row missing_field unit_out_of_range numeric_column].freeze
describe BulkResourcesUploader::CsvBulkValidator, type: :module do
  require 'zip'
  include_context 'when files were already uploaded to S3'
  include_context 'with a bulk csv file'
  let(:creator_with_units) { BulkResourcesUploader::BulkResourcesCreator.new(program_with_units) }
  let(:creator_no_units) { BulkResourcesUploader::BulkResourcesCreator.new(program_no_units) }

  before do
    allow(creator_with_units).to receive_messages(
      fetch_zip: File.open(no_errors_zip_path, 'rb'),
      s3_bucket: s3_bucket
    )
    allow(s3_bucket).to receive(:store_file_contents)
  end

  describe '#validate_bulk_process' do
    it 'reports no units program error' do
      creator_no_units.validate_bulk_process
      errors = creator_no_units.instance_variable_get(:@errors)
      expect(errors.to_s).to include("This book doesn't have units")
    end

    it 'reports files not used warning' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(csv_file_not_used)
      creator_with_units.validate_bulk_process
      warnings = creator_with_units.instance_variable_get(:@warnings)
      expect(warnings.to_s).to include('This file is not being used during resources creation')
    end

    it 'reports duplicated path error' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(duplicated_path_csv)
      creator_with_units.validate_bulk_process
      errors = creator_with_units.instance_variable_get(:@errors)
      expect(errors.to_s).to include('This file path is repeated')
    end

    it 'returns the correct errors number' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(multiple_errors_csv)
      validator_resp = creator_with_units.validate_bulk_process
      expect(validator_resp[:errors_number]).to eq(12)
    end

    it 'returns the correct warnings number' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(csv_file_not_used)
      validator_resp = creator_with_units.validate_bulk_process
      expect(validator_resp[:warnings_number]).to be_positive
    end

    it 'adds unexpected error to errors collection when exception occurs' do
      allow(creator_with_units).to receive(:fetch_bulk_csv)
                               .and_raise(StandardError.new('Unexpected error'))
      creator_with_units.validate_bulk_process
      errors = creator_with_units.instance_variable_get(:@errors)
      expect(errors.any? { |e| e[:type] == 'unexpected_error' }).to be true
    end

    it 'returns error count of 1 when unexpected error occurs' do
      allow(creator_with_units).to receive(:fetch_bulk_csv)
                               .and_raise(StandardError.new('Unexpected error'))
      validator_resp = creator_with_units.validate_bulk_process
      expect(validator_resp[:errors_number]).to eq(1)
    end

    describe 'start_unit format validation' do
      it 'accepts integer format for start_unit' do
        allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(csv_with_valid_integer)
        creator_with_units.validate_bulk_process
        errors = creator_with_units.instance_variable_get(:@errors)
        expect(errors.none? { |e| e[:type] == 'invalid_unit_format' }).to be true
      end

      it 'accepts decimal format (unit.lesson) for start_unit' do
        allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(csv_with_valid_decimal)
        creator_with_units.validate_bulk_process
        errors = creator_with_units.instance_variable_get(:@errors)
        expect(errors.none? { |e| e[:type] == 'invalid_unit_format' }).to be true
      end

      it 'rejects invalid format with multiple dots' do
        allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(csv_with_invalid_format)
        creator_with_units.validate_bulk_process
        errors = creator_with_units.instance_variable_get(:@errors)
        expect(errors.any? { |e| e[:type] == 'invalid_unit_format' }).to be true
      end

      it 'rejects non-numeric characters' do
        allow(creator_with_units).to receive(:fetch_bulk_csv)
          .and_return(csv_with_invalid_characters)
        creator_with_units.validate_bulk_process
        errors = creator_with_units.instance_variable_get(:@errors)
        expect(errors.any? { |e| e[:type] == 'invalid_unit_format' }).to be true
      end
    end
  end

  describe '#errors_breakdown' do
    let(:validator_resp) do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(multiple_errors_csv)
      creator_with_units.validate_bulk_process
    end

    it 'returns correct keys on errors breakdown' do
      expect(validator_resp[:errors_breakdown].keys).to eq(ERRORS_BREAKDOWN_KEYS)
    end

    it 'returns correct errors number on each key' do
      validator_resp[:errors_breakdown].each_key do |error_group_key|
        actual_size = validator_resp[:errors_breakdown][error_group_key][:size]
        expected_size = ERRORS_SIZE[error_group_key]
        expect(actual_size).to eq(expected_size), "Expected #{error_group_key} to have " \
                                                  "size #{expected_size}, but got #{actual_size}"
      end
    end

    it 'includes message key for each error type' do
      validator_resp[:errors_breakdown].each_value do |error_info|
        expect(error_info).to have_key(:message)
      end
    end

    it 'ensures each error message is a string' do
      validator_resp[:errors_breakdown].each_value do |error_info|
        expect(error_info[:message]).to be_a(String)
      end
    end

    it 'ensures each error message is not empty' do
      validator_resp[:errors_breakdown].each_value do |error_info|
        expect(error_info[:message]).not_to be_empty
      end
    end
  end

  describe '#errors_report_export' do
    it 'exports the csv report using the correct path' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(multiple_errors_csv)
      creator_with_units.validate_bulk_process
      errors_report_path = creator_with_units.instance_variable_get(:@csv_errors_report)
      expect(s3_bucket).to have_received(:store_file_contents).with(errors_report_path, anything)
    end

    it 'includes all error messages in the report' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(multiple_errors_csv)
      creator_with_units.validate_bulk_process
      csv_content = creator_with_units.send(:errors_report_export)
      errors = creator_with_units.instance_variable_get(:@errors)
      errors.each do |error|
        escaped_message = error[:message].gsub('"', '""')
        expect(csv_content).to include(escaped_message)
      end
    end

    it 'includes warnings section in the report' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(csv_file_not_used)
      creator_with_units.validate_bulk_process
      csv_content = creator_with_units.send(:errors_report_export)
      expect(csv_content).to include('WARNINGS')
    end

    it 'includes all warning messages in the report' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(csv_file_not_used)
      creator_with_units.validate_bulk_process
      csv_content = creator_with_units.send(:errors_report_export)
      warnings = creator_with_units.instance_variable_get(:@warnings)
      warnings.each do |warning|
        expect(csv_content).to include(warning[:message])
      end
    end

    it 'includes row_number header in the report' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(multiple_errors_csv)
      creator_with_units.validate_bulk_process
      csv_content = creator_with_units.send(:errors_report_export)
      expect(csv_content).to include('row_number')
    end

    it 'includes path header in the report' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(multiple_errors_csv)
      creator_with_units.validate_bulk_process
      csv_content = creator_with_units.send(:errors_report_export)
      expect(csv_content).to include('path')
    end

    it 'includes message header in the report' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(multiple_errors_csv)
      creator_with_units.validate_bulk_process
      csv_content = creator_with_units.send(:errors_report_export)
      expect(csv_content).to include('message')
    end

    it 'includes type header in the report' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(multiple_errors_csv)
      creator_with_units.validate_bulk_process
      csv_content = creator_with_units.send(:errors_report_export)
      expect(csv_content).to include('type')
    end
  end

  describe '#csv_file_name behavior' do
    let(:tracker) { create(:bulk_resources_creation_tracker, program_id: program_with_units.id) }

    before do
      allow(creator_with_units).to receive_messages(
        fetch_bulk_csv: multiple_errors_csv,
        s3_bucket: s3_bucket
      )
      allow(s3_bucket).to receive(:store_file_contents)
    end

    context 'when tracker has a custom csv_file_name' do
      let(:custom_file_name) { 'custom_errors_report.csv' }

      before do
        tracker.update(csv_file_name: custom_file_name)
        allow(creator_with_units).to receive(:setup_tracker)
          .with(program_with_units.id, processing_files: true).and_return(tracker)
      end

      it 'uses the custom csv_file_name from tracker' do
        response = creator_with_units.validate_bulk_process
        expect(response[:csv_file_name]).to eq("errors_#{custom_file_name}")
      end

      it 'returns the custom file name in validation response' do
        response = creator_with_units.validate_bulk_process
        expect(response).to include(csv_file_name: "errors_#{custom_file_name}")
      end
    end

    context 'when tracker csv_file_name is nil' do
      before do
        tracker.update(csv_file_name: nil)
        allow(creator_with_units).to receive(:setup_tracker)
          .with(program_with_units.id, processing_files: true).and_return(tracker)
      end

      it 'falls back to default csv_file_name' do
        response = creator_with_units.validate_bulk_process
        expect(response[:csv_file_name]).to eq('erros_report.csv')
      end

      it 'returns the default file name in validation response' do
        response = creator_with_units.validate_bulk_process
        expect(response).to include(csv_file_name: 'erros_report.csv')
      end
    end

    context 'when tracker csv_file_name is empty string' do
      before do
        tracker.update(csv_file_name: nil)
        allow(creator_with_units).to receive(:setup_tracker)
          .with(program_with_units.id, processing_files: true).and_return(tracker)
      end

      it 'falls back to default csv_file_name when empty' do
        response = creator_with_units.validate_bulk_process
        expect(response[:csv_file_name]).to eq('erros_report.csv')
      end
    end

    context 'when tracker csv_file_name is set during validation' do
      before do
        allow(creator_with_units).to receive(:setup_tracker)
          .with(program_with_units.id, processing_files: true).and_return(tracker)
      end

      it 'updates tracker with new csv_file_name' do
        new_file_name = 'updated_errors_report.csv'
        tracker.update(csv_file_name: new_file_name)
        response = creator_with_units.validate_bulk_process
        expect(response[:csv_file_name]).to eq("errors_#{new_file_name}")
      end

      it 'persists the csv_file_name in tracker after validation' do
        file_name = 'persistent_errors_report.csv'
        tracker.update(csv_file_name: file_name)
        creator_with_units.validate_bulk_process
        expect(tracker.reload.csv_file_name).to eq(file_name)
      end
    end

    context 'when tracker is created with csv_file_name patterns matching' do
      before do
        allow(creator_with_units).to receive(:setup_tracker)
          .with(program_with_units.id, processing_files: true).and_return(tracker)
      end

      it 'accepts program-specific file names' do
        program_file_name = "#{program_with_units.id}_errors_report.csv"
        tracker.update(csv_file_name: program_file_name)
        response = creator_with_units.validate_bulk_process
        expect(response[:csv_file_name]).to eq("errors_#{program_file_name}")
      end

      it 'accepts timestamp-based file names' do
        timestamp_file_name = "errors_report_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
        tracker.update(csv_file_name: timestamp_file_name)
        response = creator_with_units.validate_bulk_process
        expect(response[:csv_file_name]).to eq("errors_#{timestamp_file_name}")
      end

      it 'accepts descriptive file names' do
        descriptive_file_name = 'bulk_upload_validation_errors.csv'
        tracker.update(csv_file_name: descriptive_file_name)
        response = creator_with_units.validate_bulk_process
        expect(response[:csv_file_name]).to eq("errors_#{descriptive_file_name}")
      end
    end
  end
end
