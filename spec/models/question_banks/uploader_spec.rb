describe QuestionBanks::Uploader do
  include ActionDispatch::TestProcess::FixtureFile

  let(:question_bank) { build(:question_bank) }
  let(:topic) { create(:question_bank_topic) }
  let(:user) { build_stubbed(:user) }

  let(:fixture_filename) do
    'question_bank_multiple_choice_3_choices_windows-1252.csv'
  end

  let(:fixture_file) { "spec/fixtures/csv/#{fixture_filename}" }
  let(:raw_csv) { File.read(fixture_file, encoding: 'ASCII-8BIT') }
  let(:upload) { fixture_file_upload(fixture_file, 'text/csv') }

  describe '#question_bank' do
    let(:uploader) { described_class.new(topic, upload, user) }

    context 'when no question bank provided,' do
      it 'returns a question bank instance' do
        expect(uploader.question_bank).to be_a(QuestionBank)
      end

      it 'populates the new question bank instance with the specified ' \
         'topic' do
        expect(uploader.question_bank).to have_attributes(
          question_bank_topic_id: topic.id
        )
      end
    end

    it 'returns the existing question bank if provided' do
      uploader.existing_question_bank = question_bank

      expect(uploader.question_bank).to be_a(QuestionBank)
      expect(uploader.question_bank).to eq(question_bank)
    end
  end

  describe '#upload' do
    let(:importer_class) { QuestionBanks::Importer }
    let(:importer) { instance_double(importer_class, import: nil) }

    before do
      allow(QuestionBank).to receive(:new).and_return(question_bank)
      allow(QuestionBanks::Importer).to receive(:new).and_return(importer)
    end

    context 'when no csv file is provided,' do
      let(:uploader) { described_class.new(topic, nil, user) }

      before { uploader.upload }

      it 'sets an error on the question_bank instance' do
        expect(uploader.question_bank.errors.full_messages).to include(
          'No CSV file was provided'
        )
      end

      it 'does not attempt an import' do
        expect(importer_class).not_to have_received(:new)
      end
    end

    context 'when a file infected with a virus is provided,' do
      let(:virus_name) { 'my_bad_virus' }
      let(:infected_file) do
        ActionController::Parameters.new(
          infected: 'true', virus_name: virus_name
        )
      end
      let(:uploader) { described_class.new(topic, infected_file, user) }

      before { uploader.upload }

      it 'sets an error on the question_bank instance' do
        expect(uploader.question_bank.errors.full_messages).to include(
          /infected with the virus '#{virus_name}'/
        )
      end

      it 'does not attempt an import' do
        expect(importer_class).not_to have_received(:new)
      end
    end

    context 'when a csv file is provided,' do
      let(:uploader) { described_class.new(topic, upload, user) }

      it 'instantiates a QuestionBanks::Importer instance, passing in ' \
         'the question bank instance and an array of lines read from ' \
         'the csv file' do
        uploader.upload

        lines = File.readlines(fixture_file, encoding: 'ASCII-8BIT')

        expect(QuestionBanks::Importer).to have_received(:new).with(
          filename: fixture_filename,
          lines: lines,
          question_bank: question_bank,
          raw_csv: raw_csv,
          user: user
        )
      end

      it 'calls .import on the QuestionBanks::Importer instance' do
        uploader.upload

        expect(importer).to have_received(:import)
      end

      it 'returns true if the QuestionBank instance has no errors' do
        uploader.question_bank.errors.clear

        expect(uploader.upload).to be_truthy
      end

      it 'returns false if the QuestionBank instance has errors' do
        uploader.question_bank.errors.add(:base, 'some error')

        expect(uploader.upload).to be_falsey
      end
    end
  end
end
