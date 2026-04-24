RSpec.describe BulkResourcesUploader::BulkResourcesCreator, core: true do
  require 'zip'
  include_context 'when files were already uploaded to S3'
  let(:creator_with_units) { described_class.new(program_with_units, tracker) }
  let(:creator_no_units) { described_class.new(program_no_units) }
  let(:tracker) { create(:bulk_resources_creation_tracker, program_id: program_with_units.id) }
  let(:correct_units_info) { program_with_units.units.map { |unit| unit_info(unit) } }
  let(:root_path) { "admin_tasks/bulk_irs/#{M3::Application.config.current_deployed_env_name}" }

  def unit_info(unit)
    {
      unit_rank: unit.rank.to_i + 1,
      lesson_ranks: unit.lessons.map { |lesson| lesson.rank.to_i + 1 }
    }
  end

  before do
    # create_zipfile comes from spec/support/zip_file_helper.rb
    allow(creator_with_units).to receive(:fetch_zip)
                             .and_return(File.open(no_errors_zip_path, 'rb'))
    allow(creator_with_units).to receive(:fetch_bulk_csv).and_return(correct_csv_content)
    allow(creator_with_units).to receive(:s3_bucket).and_return(s3_bucket)
    allow(s3_bucket).to receive(:move_file)
    allow(s3_bucket).to receive(:store_file_contents)
    tracker.job_created!
  end

  describe '#units_info' do
    context 'when program has no units' do
      it 'returns an empty array' do
        expect(creator_no_units.instance_variable_get(:@units_info)).to be_empty
      end
    end

    context 'when program has units' do
      it 'returns correct units info with ranks and lessons' do
        expect(creator_with_units.instance_variable_get(:@units_info)).to eq(correct_units_info)
      end

      it 'includes the correct number of units from the program' do
        units_info = creator_with_units.instance_variable_get(:@units_info)
        expect(units_info.length).to eq(program_with_units.units.count)
      end

      it 'has unit ranks starting from 1' do
        units_info = creator_with_units.instance_variable_get(:@units_info)
        program_ranks = program_with_units.units.map { |unit| unit.rank.to_i + 1 }
        unit_ranks = units_info.pluck(:unit_rank)
        expect(unit_ranks).to match_array(program_ranks)
      end

      it 'has sorted lesson ranks for each unit' do
        units_info = creator_with_units.instance_variable_get(:@units_info)
        units_info.each do |unit_info|
          expect(unit_info[:lesson_ranks]).to eq(unit_info[:lesson_ranks].sort)
        end
      end
    end

    context 'when program is nil' do
      let(:creator_nil_program) { described_class.new(nil) }

      it 'returns an empty array' do
        expect(creator_nil_program.instance_variable_get(:@units_info)).to eq([])
      end
    end
  end

  describe '#path_creator' do
    context 'when program exists' do
      it 'returns the correct zip_file_s3_path' do
        zip_file_s3_path = "#{root_path}/#{program_with_units.id}/" \
                           "#{program_with_units.id}_m3_resources.zip"
        expect(creator_with_units.path_creator(:zip_file_s3_path)).to eq(zip_file_s3_path)
      end

      it 'returns the correct csv_s3_path' do
        csv_s3_path = "#{root_path}/#{program_with_units.id}/" \
                      "#{program_with_units.id}_m3_resources.csv"
        expect(creator_with_units.path_creator(:csv_s3_path)).to eq(csv_s3_path)
      end

      it 'returns the correct csv_errors_report path' do
        csv_errors_report = "#{root_path}/#{program_with_units.id}/" \
                            "#{program_with_units.id}_errors_report.csv"
        expect(creator_with_units.path_creator(:csv_errors_report)).to eq(csv_errors_report)
      end

      it 'returns the correct unziped_path' do
        unziped_path = "#{root_path}/#{program_with_units.id}/unziped"
        expect(creator_with_units.path_creator(:unziped_path)).to eq(unziped_path)
      end
    end

    context 'when program is nil' do
      let(:creator_nil_program) { described_class.new(nil) }

      it 'returns empty string for zip_file_s3_path' do
        expect(creator_nil_program.path_creator(:zip_file_s3_path)).to eq('')
      end

      it 'returns empty string for csv_s3_path' do
        expect(creator_nil_program.path_creator(:csv_s3_path)).to eq('')
      end

      it 'returns empty string for csv_errors_report' do
        expect(creator_nil_program.path_creator(:csv_errors_report)).to eq('')
      end

      it 'returns empty string for unziped_path' do
        expect(creator_nil_program.path_creator(:unziped_path)).to eq('')
      end
    end
  end

  describe '#unzip' do
    before do
      creator_with_units.unzip
    end

    it 'stores each unzipped file in the correct S3 location' do
      unziped_path = creator_with_units.path_creator(:unziped_path)

      Zip::File.open(creator_with_units.fetch_zip) do |zip|
        zip.each do |entry|
          next if entry.name.end_with?('/')

          file_content = entry.get_input_stream.read
          expect(s3_bucket).to have_received(:store_file_contents).with(
            File.join(unziped_path, entry.name), file_content
          )
        end
      end
    end
  end

  describe '#generate_resources' do
    before do
      tracker.start_unzipping!
      tracker.unzipping_completed!
      creator_with_units.generate_resources
    end

    it 'creates the expected number of resources from CSV' do
      csv_resources_count = correct_csv_content.lines.count - 1
      expect(Resource.count).to eq(csv_resources_count)
    end

    it 'creates resources with titles matching CSV data' do
      DemoData::CSV.rows(creator_with_units.fetch_bulk_csv, true) do |row|
        expect(Resource.exists?(title: row[:clean_title])).to be(true)
      end
    end

    it 'associates resources with correct unit ranks from CSV' do
      DemoData::CSV.rows(creator_with_units.fetch_bulk_csv, true) do |row|
        resource = Resource.find_by(title: row[:clean_title])
        expect(resource.unit.rank).to eq(row[:start_unit].to_i - 1)
      end
    end

    it 'sets VHL as the source for all created resources' do
      expect(Resource.distinct.pluck(:source).uniq).to eq(['VHL'])
    end
  end
end
