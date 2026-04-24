require 'tasks/demo_data/csv'

describe DemoData::CSV do
  before do
    @csvfilepath = File.join(File.dirname(__FILE__), 'tmp.csv')

    csv_data = 'id,field1,field2' + "\n" + '1,"field1_content","field2_content"'

    File.open(@csvfilepath, 'w') { |file| file.write(csv_data) }
  end

  after do
    File.unlink(@csvfilepath) if File.exist?(@csvfilepath)
  end

  context 'when is_csv_data is false' do
    it 'reads headers' do
      described_class.rows(@csvfilepath) do |row|
        expect(row[:id]).not_to be_nil
        expect(row[:field1]).not_to be_nil
        expect(row[:field2]).not_to be_nil
      end
    end

    it 'reads values' do
      described_class.rows(@csvfilepath) do |row|
        expect(row[:id]).to eql('1')
        expect(row[:field1]).to eql('field1_content')
        expect(row[:field2]).to eql('field2_content')
      end
    end
  end

  context 'when is_csv_data is true' do
    let(:temp_file) { instance_double(Tempfile, write: nil, close: nil, unlink: nil) }
    let(:csv_hash_reader) { instance_double(CSVHashReader, each: nil) }
    let(:expected_file_contents) { 'id,campo1,campo2' + "\n" + '1,"contenido1","contenido2"' }

    before do
      allow(Tempfile).to receive(:new).and_return(temp_file)
      allow(CSVHashReader).to receive(:new).and_return(csv_hash_reader)
    end

    it 'instantiates a Tempfile and writes to it the given string' do
      described_class.rows(expected_file_contents, _is_csv_data = true)
      expect(temp_file).to have_received(:write).with(expected_file_contents)
    end

    it 'pases the file to the HashReader' do
      described_class.rows(expected_file_contents, _is_csv_data = true)
      expect(CSVHashReader).to have_received(:new).with(temp_file)
    end

    it 'closes and deletes the file' do
      described_class.rows(expected_file_contents, _is_csv_data = true)
      expect(temp_file).to have_received(:close).at_least(:once)
      expect(temp_file).to have_received(:unlink)
    end

    it 'closes and deletes the file even if an exception occurred' do
      expected_exception = 'bad CSV file'
      allow(CSVHashReader).to receive(:new).and_raise(expected_exception)
      expect do
        described_class.rows(expected_file_contents, _is_csv_data = true)
      end.to raise_error expected_exception
      expect(temp_file).to have_received(:close).at_least(:once)
      expect(temp_file).to have_received(:unlink)
    end
  end
end
