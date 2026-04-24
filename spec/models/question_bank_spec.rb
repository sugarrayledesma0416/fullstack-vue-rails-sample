describe QuestionBank do
  let(:topic) { create(:question_bank_topic) }
  let(:user) { create(:user) }
  let(:filename) { 'file.csv' }

  let(:json) do
    File.read(
      File.join('spec', 'fixtures', 'json', 'open_ended_question_bank.json')
    )
  end

  let(:valid_attrs) do
    { content_json: json, question_bank_topic: topic, title: 'abc' }
  end

  describe 'callbacks' do
    describe 'after save' do
      let(:question_bank) { described_class.new(valid_attrs) }

      it 'creates a new question bank revision record' do
        question_bank.save!
        revision = question_bank.question_bank_revisions.last

        expect(revision).to be_persisted
      end

      it 'sets the content_json of the revision record to the ' \
         'content_json attribute' do
        question_bank.save!
        revision = question_bank.question_bank_revisions.last

        expect(revision.content_json).to eq(json)
      end

      it 'sets the changed_by_id of the revision record to the ' \
         'changed_by_id attribute' do
        question_bank.changed_by_id = user.id
        question_bank.save!

        revision = question_bank.question_bank_revisions.last

        expect(revision.changed_by_id).to eq(user.id)
      end

      it 'sets the upload_filename of the revision record to the ' \
         'upload_filename attribute' do
        question_bank.upload_filename = filename
        question_bank.save!

        revision = question_bank.question_bank_revisions.last

        expect(revision.upload_filename).to eq(filename)
      end

      it 'sets the uploaded_csv of the revision record to the ' \
         'uploaded_csv attribute' do
        question_bank.uploaded_csv = 'blah,blah'
        question_bank.save!

        revision = question_bank.question_bank_revisions.last

        expect(revision.uploaded_csv).to eq('blah,blah')
      end
    end
  end

  describe '#last_revised_at' do
    it 'returns the updated_at attribute of the latest revision' do
      question_bank = described_class.create!(valid_attrs)

      # Trigger any change to create a new revision
      question_bank.uploaded_csv = 'blah'
      question_bank.save!

      expect(question_bank.last_revised_at).to eq(
        QuestionBankRevision.last.updated_at
      )
    end
  end

  describe '#last_upload_filename' do
    it 'returns the upload_filename attribute of the latest revision' do
      question_bank = described_class.create!(
        valid_attrs.merge(upload_filename: 'old filename')
      )

      question_bank.upload_filename = 'new filename'
      question_bank.save!

      expect(question_bank.last_upload_filename).to eq('new filename')
    end
  end

  describe '#last_changed_by_name' do
    it 'returns an empty string if the changed_by_id attribute of the ' \
       'latest revision is not set' do
      question_bank = described_class.create!(valid_attrs)

      expect(question_bank.last_changed_by_name).to eq('')
    end

    it 'returns an empty string if the changed_by_id attribute of the ' \
       'latest revision is not the id of any user, archived or unarchived' do
      question_bank = described_class.create!(
        valid_attrs.merge(changed_by_id: 'badid')
      )

      expect(question_bank.last_changed_by_name).to eq('')
    end

    it 'returns the full name of the user matching the changed_by_id ' \
       'attribute of the latest revision when it is set' do
      other_user = create(:user)

      question_bank = described_class.create!(
        valid_attrs.merge(changed_by_id: other_user.id)
      )

      question_bank.changed_by_id = user.id
      question_bank.save!

      expect(question_bank.last_changed_by_name).to eq(user.full_name)
    end

    it 'returns the full name of the user matching the changed_by_id ' \
       'attribute of the latest revision even if that user is archived' do
      user.update!(archived: true)
      question_bank = described_class.create!(
        valid_attrs.merge(changed_by_id: user.id)
      )

      expect(question_bank.last_changed_by_name).to eq(user.full_name)
    end
  end

  describe '#current_live_revision' do
    it 'returns the live revision of a question bank' do
      question_bank = described_class.create!(valid_attrs)
      revision_attrs = { activity_id: question_bank.question_bank_revisions.first.activity_id, content_json: json, upload_filename: filename }
      live_revision = QuestionBankRevision.create!(revision_attrs)
      live_revision.update!(status: 'live')
      QuestionBankRevision.create!(revision_attrs).update!(status: 'archived')
      QuestionBankRevision.create!(revision_attrs).update!(status: 'rejected')
      QuestionBankRevision.create!(revision_attrs).update!(status: 'archived')

      expect(question_bank.current_live_revision.id).to eq(live_revision.id)
    end
  end
end
