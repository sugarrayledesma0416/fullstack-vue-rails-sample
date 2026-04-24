require 'tasks/question_bank_topic_parser'

describe QuestionBankTopicParser do
  before(:each) do
    ENV['filename'] = 'test_topics.csv'
    @parser = described_class.new
  end

  after(:each) do
    File.unlink(@parser.filename) if File.exist?(@parser.filename)
  end

  describe '#validate' do
    context 'when the import file contains a name, description, language and level' do
      it 'returns true' do
        csv_data = 'name,description,language,level' + "\n" + '"topic 1","some description","spanish","intro"'
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        expect(@parser.validate).to be true
      end
    end

    context 'when the import file is missing a header' do
      it 'returns false' do
        csv_data = 'name,description,language' + "\n" + 'topic 1,'
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        expect(@parser.validate).to be false
      end
    end

    context 'when the import file is missing a topic name' do
      it 'returns false' do
        csv_data = 'name,description,language,level' + "\n" + ','
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        expect(@parser.validate).to be false
      end
    end

    context 'when the import file contains no data' do
      it 'returns false' do
        csv_data = 'name,description,language,level' + "\n" + ''
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        expect(@parser.validate).to be false
      end
    end
  end

  describe '#import' do
    context 'when the import file contains no errors' do
      it 'imports the topic data' do
        csv_data = 'name,description,language,level' + "\n" + '"topic 1","some description","spanish","intro"'
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        @parser.import
        expect(@parser.errors).to be_empty
      end
    end

    context 'when the import file contains errors' do
      it 'returns an errors array' do
        csv_data = 'name,description,language,level' + "\n" + ',"some description"'
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        @parser.import
        expect(@parser.errors).not_to be_empty
      end
    end
  end
end
