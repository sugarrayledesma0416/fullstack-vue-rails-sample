ENTRIES = %w[Activity/phonetics.doc Activity/sociolinguistic.pdf Activity/spanish.mp3].freeze
RSpec.describe BulkResourcesUploader::BulkResourcesUtils, type: :module do
  include_context 'when files were already uploaded to S3'
  let(:creator_with_units) { BulkResourcesUploader::BulkResourcesCreator.new(program_with_units) }

  before do
    allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(correct_csv_content)
    allow(creator_with_units).to receive(:fetch_zip)
                             .and_return(File.open(no_errors_zip_path, 'rb'))
  end

  describe '#csv_column_extractor' do
    it 'returns an array with the specified column data' do
      array_resp = creator_with_units.csv_column_extractor(:source_file_path)
      DemoData::CSV.rows(correct_csv_content, true) do |row|
        expect(array_resp).to include(row[:source_file_path])
      end
    end
  end

  describe '#create_entries_array' do
    it 'returns an array using the zip file entries' do
      entries_array = creator_with_units.create_entries_array
      expect(entries_array).to eq(ENTRIES)
    end
  end
end
