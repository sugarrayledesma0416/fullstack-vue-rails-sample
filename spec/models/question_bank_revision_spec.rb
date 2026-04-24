describe QuestionBankRevision do
  let(:user) { create(:user) }
  let(:filename) { 'file.csv' }
  let!(:question_bank_topic) { create(:question_bank_topic) }

  let(:json) do
    File.read(
      File.join('spec', 'fixtures', 'json', 'open_ended_question_bank.json')
    )
  end

  let!(:question_bank) do
    create(
      :question_bank,
      changed_by_id: user.id,
      content_json: json,
      question_bank_topic: question_bank_topic,
      upload_filename: 'fake_file.csv'
    )
  end

  let(:valid_attrs) do
    { activity_id: question_bank.question_bank_revisions.first.activity_id, content_json: json, upload_filename: filename }
  end

  context 'callbacks' do
    context 'before_create' do
      it 'sets the status to pending' do
        question_bank_revision = described_class.create!(valid_attrs)

        expect(question_bank_revision.status).to eq('pending')
      end
    end
  end

  describe '#last_changed_by_name' do
    it 'returns an empty string if the changed_by_id attribute of the ' \
       'latest revision is not set' do
      question_bank_revision = described_class.create!(valid_attrs)

      expect(question_bank_revision.last_changed_by_name).to eq('')
    end

    it 'returns an empty string if the changed_by_id attribute of the ' \
       'latest revision is not the id of any user, archived or unarchived' do
      question_bank_revision = described_class.create!(
        valid_attrs.merge(changed_by_id: 'badid')
      )

      expect(question_bank_revision.last_changed_by_name).to eq('')
    end

    it 'returns the full name of the user matching the changed_by_id ' \
       'attribute of the latest revision when it is set' do
      other_user = create(:user)

      question_bank_revision = described_class.create!(
        valid_attrs.merge(changed_by_id: other_user.id)
      )

      question_bank_revision.changed_by_id = user.id
      question_bank_revision.save!

      expect(question_bank_revision.last_changed_by_name).to eq(user.full_name)
    end

    it 'returns the full name of the user matching the changed_by_id ' \
       'attribute of the latest revision even if that user is archived' do
      user.update!(archived: true)
      question_bank_revision = described_class.create!(
        valid_attrs.merge(changed_by_id: user.id)
      )

      expect(question_bank_revision.last_changed_by_name).to eq(user.full_name)
    end
  end
end
