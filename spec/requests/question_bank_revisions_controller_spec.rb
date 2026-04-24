require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'
require 'requests/shared_question_bank_editor_examples'

describe QuestionBankRevisionsController do
  let(:topic) { create(:question_bank_topic) }
  let(:fixture_filename) do
    'question_bank_open_ended_windows-1252.csv'
  end

  let(:fixture_file) { "spec/fixtures/csv/#{fixture_filename}" }
  let(:raw_csv) { File.read(fixture_file, encoding: 'ASCII-8BIT') }
  let(:user) { create(:user) }
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
      question_bank_topic: topic,
      upload_filename: fixture_filename
    )
  end

  describe 'GET /download' do
    def do_request
      get(
        download_question_bank_revision_path(
          id: question_bank.question_bank_revisions.last.id
        )
      )
    end

    include_examples 'require logged in user'
    include_examples 'require a question bank editor'

    context 'with a logged in user who is a question bank editor' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
        question_bank.question_bank_revisions.first.update!(uploaded_csv: raw_csv)
      end

      it 'downloads the revision csv' do
        do_request

        expect(response.body).to eq(raw_csv)
      end
    end
  end

  describe 'POST /approve' do
    def do_request
      post(
        approve_question_bank_revision_path(
          id: question_bank.question_bank_revisions.last.id
        )
      )
    end

    include_examples 'require logged in user'
    include_examples 'require a question bank editor'

    def redirect_link
      question_bank_topic_question_bank_question_bank_revisions_path(
        question_bank_topic_id: topic.id,
        question_bank_id: question_bank.id
      )
    end

    context 'with a logged in user who is a question bank editor' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
      end

      it 'approves the revision' do
        question_bank.question_bank_revisions.first.update!(status: 'pending')
        do_request

        new_log_entry = QuestionBankRevisionLog.last
        expect(new_log_entry).to have_attributes(
          question_bank_revision_id: question_bank.question_bank_revisions.first.id,
          status: 'live',
          user_id: user.id
        )
        expect(question_bank.question_bank_revisions.first.status).to eq('live')
        expect(response).to redirect_to(redirect_link)
      end
    end
  end

  describe 'POST /reject' do
    def do_request
      post(
        reject_question_bank_revision_path(
          id: question_bank.question_bank_revisions.last.id
        )
      )
    end

    include_examples 'require logged in user'
    include_examples 'require a question bank editor'

    def redirect_link
      question_bank_topic_question_bank_question_bank_revisions_path(
        question_bank_topic_id: topic.id,
        question_bank_id: question_bank.id
      )
    end

    context 'with a logged in user who is a question bank editor' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
      end

      it 'rejects the revision' do
        question_bank.question_bank_revisions.first.update!(status: 'pending')
        do_request

        new_log_entry = QuestionBankRevisionLog.last
        expect(new_log_entry).to have_attributes(
          question_bank_revision_id: question_bank.question_bank_revisions.first.id,
          status: 'rejected',
          user_id: user.id
        )
        expect(question_bank.question_bank_revisions.first.status).to eq('rejected')
        expect(response).to redirect_to(redirect_link)
      end
    end
  end

  describe 'POST /archive' do
    def do_request
      post(
        archive_question_bank_revision_path(
          id: question_bank.question_bank_revisions.last.id
        )
      )
    end

    include_examples 'require logged in user'
    include_examples 'require a question bank editor'

    def redirect_link
      question_bank_topic_question_bank_question_bank_revisions_path(
        question_bank_topic_id: topic.id,
        question_bank_id: question_bank.id
      )
    end

    context 'with a logged in user who is a question bank editor' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
      end

      it 'archives the revision' do
        question_bank.question_bank_revisions.first.update!(status: 'live')
        do_request

        new_log_entry = QuestionBankRevisionLog.last
        expect(new_log_entry).to have_attributes(
          question_bank_revision_id: question_bank.question_bank_revisions.first.id,
          status: 'archived',
          user_id: user.id
        )
        expect(question_bank.question_bank_revisions.first.status).to eq('archived')
        expect(response).to redirect_to(redirect_link)
      end
    end
  end
end
