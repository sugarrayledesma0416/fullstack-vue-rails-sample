describe QuestionBankContent do
  let(:question_bank) { build(:question_bank) }
  let(:json) do
    File.read(
      File.join('spec', 'fixtures', 'instructor_created_activity_content.json')
    )
  end

  it 'generates a QuestionBankContent object' do
    question_bank.content_json = json
    question_bank.save!

    expect(question_bank.activity_content).to be_a described_class
  end

  describe '#generate_content_json' do
    let(:content_object) do
      instance_double(
        MaestroActivityEngine::ActivityContent::Content,
        to_json: json
      )
    end

    before do
      allow(question_bank).to receive(:content_object) { content_object }
    end

    it 'converts the content object to json' do
      question_bank.generate_content_json

      expect(content_object).to have_received(:to_json).with(indent: 2)
    end

    it 'returns the generated json' do
      expect(question_bank.generate_content_json).to eq(json)
    end
  end

  describe '#content_json' do
    it 'returns the json from the revision record referenced by the ' \
       'question_bank_revision_id' do
      question_bank.content_json = json
      question_bank.save!

      # reload this way to get rid of instance variables that have
      # previously been set
      reloaded_question_bank = QuestionBank.find(question_bank.id)

      expect(reloaded_question_bank.content_json).to eq(json)
    end

    it 'returns nil when does not have current revision' do
      question_bank.content_json = json
      question_bank.save!

      QuestionBankRevision.find_by(activity_id: question_bank.id).destroy

      # reload this way to get rid of instance variables that have
      # previously been set
      reloaded_question_bank = QuestionBank.find(question_bank.id)

      expect(reloaded_question_bank.content_json).to be_nil
    end
  end
end
