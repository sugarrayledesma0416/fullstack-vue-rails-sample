require 'rails_helper'

describe DictionaryEntriesExport::DictionaryEntriesReport do
  include_context 'when the program contains the activities with supported activity_types'
  include_context 'when the program does not contain the activities'
  include_context 'with dictionary entries s3 data'
  include_context 'with dictionary entries report data'
  let(:program_id) { program.id }
  let(:cms_activity_ids) { activities.pluck(:cms_activity_id).map(&:to_s) }
  let(:file_name) { "#{program_id}-#{cms_activity_ids.join('-')}.csv" }

  before do
    allow(report).to receive(:s3_bucket).and_return(s3_bucket)
    allow(report).to receive(:temp_csv_file).and_return(temp_csv_file)
  end

  describe '#initialize' do
    it 'assigns the program ID and activity IDs' do
      expect(report.instance_variable_get(:@program_id)).to eq(program_id)
      expect(report.instance_variable_get(:@cms_activity_ids)).to eq(cms_activity_ids)
    end

    it 'sets the file name and file path correctly' do
      expect(report.file_name).to start_with("#{program_id}-#{cms_activity_ids.join('-')}")
      expect(report.file_path).to start_with("tasks/dictionary_entries_reports/#{program_id}-#{cms_activity_ids.join('-')}")
    end
  end

  describe '#pre_process_validation' do
    context 'when activity type is supported' do
      before do
        program.activities.each { _1.update(activity_type: 'vocabulary_tutorial') }
      end

      it 'returns an empty array' do
        suported_report = described_class.new(program_id:, cms_activity_ids:)
        errors = suported_report.pre_process_validation
        expect(errors).to be_empty
      end
    end

    context 'when activity type is not supported' do
      before do
        program.activities.each { _1.update(activity_type: 'unsupported_type') }
      end

      it 'returns an array with error message' do
        unsuported_report = described_class.new(program_id:, cms_activity_ids:)
        errors = unsuported_report.pre_process_validation
        expect(errors).to include("Unsupported activity type 'unsupported_type'" \
                                  ' for dictionary entries report.')
      end
    end

    context 'when the cms activities does not belong to the program' do
      it 'returns an array with error message' do
        errors = report_no_activities.pre_process_validation
        expect(errors).to include("Activity #{cms_activity_ids.first} " \
                                  "is not present in program #{program_no_activities.id}.")
      end
    end
  end

  describe '#generate_csv_file' do
    let(:unit) { create(:unit, program: program) }
    let(:lesson) { create(:lesson, unit: unit) }
    let(:activity) { create(:activity, cms_activity_id: cms_activity_ids.first, lesson: lesson, activity_type: 'vocabulary_tutorial') }
    let(:content_object) { instance_double('ContentObject') }
    let(:say_it) { instance_double('SayIt') }
    let(:listen_and_repeat) { instance_double('ListenAndRepeat') }
    let(:match) { instance_double('Match') }
    let(:dictionary_entry) do
      instance_double(
        'DictionaryEntry',
        id: 1,
        target: 'test word',
        language: 'en',
        descriptor: 'test descriptor',
        translation: 'test translation',
        target_for_speech_rec: 'test machine word',
        audio: nil,
        image: nil
      )
    end
    let(:activity_content) { instance_double('ActivityContent', content: '<vocabulary_tutorial></vocabulary_tutorial>') }
    let(:strand) { instance_double('Strand', title: 'Test Strand') }

    before do
      allow(CSV).to receive(:open).and_yield(csv)
      allow(csv).to receive(:<<)
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(activity).to receive(:activity_content).and_return(activity_content)
      allow(activity).to receive(:strand).and_return(strand)
      allow(lesson).to receive(:toc_entries).and_return([])
      allow(content_object).to receive(:say_it).and_return([say_it])
      allow(content_object).to receive(:listen_and_repeat).and_return([listen_and_repeat])
      allow(content_object).to receive(:match).and_return([match])
      allow(say_it).to receive(:dictionary_entries).and_return([dictionary_entry])
      allow(listen_and_repeat).to receive(:dictionary_entries).and_return([dictionary_entry])
      allow(match).to receive(:ordered_dictionary_entries).and_return([dictionary_entry])
      allow(report).to receive(:first_activity_in_program).with(cms_activity_ids.first, program_id).and_return(activity)
      allow(report).to receive(:first_activity_in_program).with(cms_activity_ids.last, program_id).and_return(activity)
    end

    it 'generates a CSV with the correct headers' do
      report.generate_csv_file
      expect(CSV).to have_received(:open)
        .with(temp_file_path, 'wb', write_headers: true, headers:)
    end
  end

  describe '#upload_csv_file' do
    before do
      allow(report).to receive(:upload_file_no_cache).and_return(true)
      allow(File).to receive(:open).and_return(true)
    end

    it 'uploads the CSV file to S3' do
      report.upload_csv_file
      expect(report).to have_received(:upload_file_no_cache)
    end
  end

  describe '#csv_exists_in_s3?' do
    it 'returns true if the CSV exists in S3' do
      expect(report.csv_exists_in_s3?).to be(true)
    end

    it 'returns false if the CSV does not exist in S3' do
      report_file_path = report.instance_variable_get(:@file_path)
      allow(s3_bucket).to receive(:file_exist?).with(report_file_path).and_return(false)
      expect(report.csv_exists_in_s3?).to be(false)
    end
  end

  describe '#delete_temp_csv_file' do
    before do
      allow(temp_csv_file).to receive(:close)
      allow(temp_csv_file).to receive(:unlink)
    end

    it 'closes and unlinks the temporary file' do
      report.delete_temp_csv_file
      expect(temp_csv_file).to have_received(:close)
      expect(temp_csv_file).to have_received(:unlink)
    end
  end

  describe '#signed_url' do
    let(:signed_url) { 'https://example.com/signed_url' }

    before do
      allow(Aws::CF::Signer).to receive(:sign_url).and_return(signed_url)
    end

    it 'returns a signed URL for the CSV file' do
      expect(report.signed_url).to eq(signed_url)
    end
  end
end
