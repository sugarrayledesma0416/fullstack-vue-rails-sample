RSpec.describe BulkResourcesUploader::RowValidations, type: :module do
  include_context 'when files were already uploaded to S3'
  include_context 'with a bulk csv file'
  let(:creator_with_units) { BulkResourcesUploader::BulkResourcesCreator.new(program_with_units) }
  let(:units_array) { program_with_units.units.map { |unit| unit.rank.to_i + 1 } }

  before do
    allow(creator_with_units).to receive(:fetch_zip)
                             .and_return(File.open(no_errors_zip_path, 'rb'))
  end

  describe '#units_info' do
    it 'is initialized with units info and lesson ranks' do
      expected_units_info = program_with_units.units.map do |unit|
        {
          unit_rank: unit.rank.to_i + 1,
          lesson_ranks: unit.lessons.map { |lesson| lesson.rank.to_i + 1 }.sort
        }
      end

      expect(creator_with_units.instance_variable_get(:@units_info)).to eq(expected_units_info)
    end

    it 'is empty array when program has no units' do
      creator_no_units = BulkResourcesUploader::BulkResourcesCreator.new(program_no_units)
      expect(creator_no_units.instance_variable_get(:@units_info)).to eq([])
    end
  end

  describe '#validate_rows' do
    it 'reports empty row detected error' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(empty_line_csv)
      creator_with_units.validate_bulk_process
      errors = creator_with_units.instance_variable_get(:@errors)
      expect(errors.to_s).to include('Empty row detected')
    end

    it 'reports invalid format error' do
      allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(semicolons_separated_csv)
      creator_with_units.validate_bulk_process
      errors = creator_with_units.instance_variable_get(:@errors)
      expect(errors.to_s).to include('This row is not properly comma-separated formatted')
    end

    context 'with multiple_errors_csv csv file' do
      before do
        allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(multiple_errors_csv)
        creator_with_units.validate_bulk_process
      end

      it 'reports missing mandatory fields' do
        errors = creator_with_units.instance_variable_get(:@errors)
        BulkResourcesUploader::RowValidations::MANDATORY_FIELDS.each do |mandatory_field|
          expect(errors.to_s).to include("#{mandatory_field} value is missing on your csv")
        end
      end

      it 'reports missing files' do
        errors = creator_with_units.instance_variable_get(:@errors)
        expect(errors.to_s)
          .to include("We couldn't find this file in your resources zip file: missing_file.doc")
      end

      it 'reports invalid characters' do
        errors = creator_with_units.instance_variable_get(:@errors)
        expect(errors.to_s)
          .to include('Invalid characters detected: ?')
      end

      it 'reports units out of range' do
        errors = creator_with_units.instance_variable_get(:@errors)
        expect(errors.to_s)
          .to include(
            'For this book units values should be within: ' \
            "#{units_array}"
          )
      end

      it 'reports non numeric type on end unit' do
        errors = creator_with_units.instance_variable_get(:@errors)
        expect(errors.to_s)
          .to include('end_unit value must be a number')
      end
    end
  end
end
