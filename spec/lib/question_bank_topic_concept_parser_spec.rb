require 'tasks/question_bank_topic_concept_parser'

describe QuestionBankTopicConceptParser do
  let!(:topic) { create(:question_bank_topic) }
  let!(:concept_1) { create(:concept) }
  let!(:concept_2) { create(:concept) }

  before(:each) do
    ENV['filename'] = 'test_topic_mapping.csv'
    @parser = described_class.new
  end

  after(:each) do
    File.unlink(@parser.filename) if File.exist?(@parser.filename)
  end

  describe '#validate' do
    context 'when the import file contains a topic_id and concept_id' do
      it 'returns true' do
        csv_data = 'topic_name,topic_id,concept_id' + "\n" + '"#{topic.name}","#{topic.id}","#{concept_1.id};#{concept_2.id}"'
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        expect(@parser.validate).to be true
      end
    end

    context 'when the import file is missing a header' do
      it 'returns false' do
        csv_data = 'topic_name,topic_id' + "\n" + '"#{topic.name}",,'
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        expect(@parser.validate).to be false
      end
    end

    context 'when the import file is missing a topic id' do
      it 'returns false' do
        csv_data = 'topic_name,topic_id,concept_id' + "\n" + '"#{topic.name}",,"#{concept_1.id};#{concept_2.id}"'
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        expect(@parser.validate).to be false
      end
    end

    context 'when the import file contains no data' do
      it 'returns false' do
        csv_data = 'topic_name,topic_id,concept_id' + "\n"
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        expect(@parser.validate).to be false
      end
    end
  end

  describe '#import' do
    context 'when the import file contains no errors' do
      it 'imports the topic concept data' do
        csv_data = 'topic_name,topic_id,concept_id' + "\n" + "#{topic.name},#{topic.id},#{concept_1.id};#{concept_2.id}"
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        @parser.import
        expect(@parser.errors).to be_empty
      end
    end

    context 'when the import file contains errors' do
      it 'returns an errors array' do
        csv_data = 'topic_name,topic_id,concept_id' + "\n" + "#{topic.name},,#{concept_1.id};#{concept_2.id}"
        File.open(@parser.filename, 'w') { |file| file.write(csv_data) }

        @parser.import
        expect(@parser.errors).not_to be_empty
      end
    end
  end
end
