require_relative '../../lib/tasks/demo_data/csv'
describe InstructorResourcesExport do
  include_context 'with units and lessons setup'
  let(:export_tool) { described_class.new(program) }
  let(:signed_url) { 'signed url' }
  let(:zip_file_name) { "#{program.prefix_abbreviation}_m3_resources.zip" }
  let(:zip_path) { File.join('/tmp', zip_file_name) }

  before do
    allow(Aws::CF::Signer).to receive(:sign_url).and_return(signed_url)
    create_list(:resource, 20,
                program:,
                start_unit_id: program.units.first.id,
                lesson_id: program.lessons.first.id,
                file_name: 'test_file')
  end

  def boolean_to_integer_syntax(boolean)
    boolean ? 1 : 0
  end

  describe '#fetch_and_zip_resources' do
    it 'creates a zip file with the resource files and CSV index file' do
      result_file = export_tool.fetch_and_zip_resources
      expected_csv_file_name = "#{program.prefix_abbreviation}_m3_resources.csv"
      file_names_in_zip = Zip::File.open(result_file) do |zipfile|
        zipfile.map(&:name)
      end
      expect(file_names_in_zip)
        .to match_array(program.resources.map(&:file_path) + [expected_csv_file_name])
    end

    it 'the csv file inside the zip has the expected headers' do
      header_str = %w[source_file_path start_unit end_unit component_name subcomponent_name
                      clean_title is_student_resource is_protected description].join(',')
      csv_file_name = "#{program.prefix_abbreviation}_m3_resources.csv"
      result_file = export_tool.fetch_and_zip_resources
      csv_zip_entry = Zip::File.open(result_file) do |zipfile|
        zipfile.detect { |entry| entry.name == csv_file_name }
      end
      csv_headers = csv_zip_entry.get_input_stream.readline
      expect(csv_headers).to match(header_str)
    end

    it 'creates a zip file using the program abbreviated name' do
      result_file = export_tool.fetch_and_zip_resources
      expect(File).to exist(result_file.path)
    end

    it 'uploads the zip file to S3' do
      allow(export_tool).to receive(:s3_bucket).and_return(s3_bucket)
      result_file = export_tool.fetch_and_zip_resources
      zip_file_s3_path = "tasks/instructor_resources/#{zip_file_name}"
      expect(s3_bucket)
        .to have_received(:upload_file)
        .with(zip_file_s3_path, result_file.path,
              { cache_control: 'no-cache, no-store, must-revalidate',
                content_type: 'application/zip' })
    end
  end

  describe '#export_resources_to_csv' do
    let(:csv_file_contents) do
      export_tool.export_resources_to_csv
      export_tool.instance_variable_get(:@temp_csv_file).read
    end

    it 'exports a csv file with the expected file paths' do
      program.resources.each do |resource|
        expect(csv_file_contents).to include(resource.file_path)
      end
    end

    it 'exports a csv file with the correct is_student_resource syntax' do
      DemoData::CSV.rows(csv_file_contents, true) do |row|
        resource = program.resources.find { _1.file_path == row[:source_file_path] }
        expect(row[:is_student_resource].to_i)
          .to eq(boolean_to_integer_syntax(resource.vhl_student_resource))
      end
    end

    it 'exports a csv file with the correct is_protected syntax' do
      DemoData::CSV.rows(csv_file_contents, true) do |row|
        resource = program.resources.find { _1.file_path == row[:source_file_path] }
        expect(row[:is_protected].to_i)
          .to eq(boolean_to_integer_syntax(resource.protected))
      end
    end

    it 'exports a csv file with the correct start_unit and lesson ranks' do
      DemoData::CSV.rows(csv_file_contents, true) do |row|
        resource = program.resources.find { _1.file_path == row[:source_file_path] }
        start_unit_rank = resource&.start_unit&.rank
        lesson_rank = resource&.lesson&.rank
        expect(row[:start_unit]).to eq("#{start_unit_rank + 1}.#{lesson_rank + 1}")
      end
    end

    it 'exports a csv file with the correct end_unit rank' do
      DemoData::CSV.rows(csv_file_contents, true) do |row|
        resource = program.resources.find { _1.file_path == row[:source_file_path] }
        end_unit_rank = resource&.end_unit&.rank
        expect(row[:end_unit]).to eq(end_unit_rank)
      end
    end
  end

  describe '#signed_url' do
    it 'returns a signed url for csv files' do
      export_tool.set_file_path_to_csv
      expect(export_tool.signed_url).to eq('signed url')
    end

    it 'returns a signed url for zip files' do
      export_tool.set_file_path_to_zip
      expect(export_tool.signed_url).to eq('signed url')
    end
  end

  describe '#set_file_path_to_csv' do
    it 'sets file_path and file_name to the CSV path' do
      export_tool.set_file_path_to_csv
      expect(export_tool.file_path).to eq(
        "tasks/instructor_resources/#{program.prefix_abbreviation}_m3_resources.csv"
      )
      expect(export_tool.file_name).to eq("#{program.prefix_abbreviation}_m3_resources.csv")
    end
  end

  describe '#set_file_path_to_zip' do
    it 'sets file_path and file_name to the ZIP path' do
      export_tool.set_file_path_to_zip
      expect(export_tool.file_path).to eq(
        "tasks/instructor_resources/#{program.prefix_abbreviation}_m3_resources.zip"
      )
      expect(export_tool.file_name).to eq("#{program.prefix_abbreviation}_m3_resources.zip")
    end
  end

  describe '#upload_csv_file' do
    before do
      allow(export_tool).to receive(:s3_bucket).and_return(s3_bucket)
      allow(export_tool).to receive(:temp_csv_file)
        .and_return(instance_double(Tempfile, path: csv_path))
    end

    it 'uploads the CSV file to S3' do
      export_tool.upload_csv_file
      expect(s3_bucket)
        .to have_received(:upload_file)
    end
  end

  describe '#csv_exists_in_s3?' do
    before do
      allow(export_tool).to receive(:s3_bucket).and_return(s3_bucket)
    end

    it 'returns true if the CSV exists in S3' do
      expect(export_tool.csv_exists_in_s3?).to be(true)
    end

    it 'returns false if the CSV does not exist in S3' do
      allow(s3_object).to receive(:exists?).and_return(false)
      expect(export_tool.csv_exists_in_s3?).to be(false)
    end
  end

  describe '#zip_exist_in_s3?' do
    before do
      allow(export_tool).to receive(:s3_bucket).and_return(s3_bucket)
    end

    it 'returns true if the ZIP file exists in S3' do
      expect(export_tool.zip_exist_in_s3?).to be(true)
    end
  end

  describe '#last_modified' do
    it 'returns the date of the last upload of the file' do
      allow(export_tool).to receive(:s3_bucket).and_return(s3_bucket)
      expected_modified_date = Time.current
      object = instance_double(Aws::S3::Object, last_modified: expected_modified_date)
      bucket = instance_double(Aws::S3::Bucket, object:)
      allow(s3_bucket).to receive(:bucket).and_return(bucket)
      expect(export_tool.last_modified).to eq(expected_modified_date.to_s(:rfc822))
    end
  end

  describe '#file_size' do
    it 'returns the file size of the zip file' do
      allow(export_tool).to receive(:s3_bucket).and_return(s3_bucket)
      allow(s3_bucket).to receive(:content_length).and_return(1000)
      expect(export_tool.formatted_file_size).to eq('1.00 KB')
    end
  end

  describe '#delete_files' do
    before do
      export_tool.fetch_and_zip_resources
      export_tool.delete_files
    end

    it 'deletes the local copy of the zip file' do
      expect(File).not_to exist(zip_path)
    end

    it 'deletes the local copy of the csv' do
      expect(File).not_to exist(csv_path)
    end
  end
end
