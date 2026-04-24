require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'
require 'requests/shared_question_bank_editor_examples'

describe QuestionBankTopicsController do
  let(:user) { create(:user) }

  describe 'GET /index' do
    let!(:topic) { create(:question_bank_topic, name: 'Topic B',
                                                language: 'English',
                                                level: 'Intro') }
    let!(:topic_two) { create(:question_bank_topic, name: 'Topic A',
                                                    language: 'Spanish',
                                                    level: 'Intro 2') }

    def do_request
      get question_bank_topics_path
    end

    include_examples 'require logged in user'
    include_examples 'require a question bank editor'

    context 'with a logged in user who is a question bank editor' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
      end

      it 'renders an index view with a list of current topics' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template :index

        expect(assigns(:question_bank_topics)).to eq([topic_two, topic])
        expect(assigns(:languages)).to eq(['spanish', 'english'])
        expect(assigns(:levels)).to eq(['intro 2', 'intro'])
      end
    end
  end

  describe 'GET /show' do
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

    let!(:active_question_bank) do
      create(
        :question_bank,
        changed_by_id: user.id,
        content_json: json,
        question_bank_topic: topic,
        upload_filename: fixture_filename
      )
    end

    let!(:inactive_question_bank) do
      create(
        :question_bank,
        changed_by_id: user.id,
        content_json: json,
        question_bank_topic: topic,
        upload_filename: fixture_filename
      )
    end

    let!(:pending_question_bank) do
      create(
        :question_bank,
        changed_by_id: user.id,
        content_json: json,
        question_bank_topic: topic,
        upload_filename: fixture_filename
      )
    end

    before do
      active_question_bank.question_bank_revisions.first.update!(status: 'live')
      inactive_question_bank.question_bank_revisions.first.update!(status: 'rejected')
      pending_question_bank.question_bank_revisions.first.update!(status: 'pending')
    end

    def do_request
      get question_bank_topic_path(id: topic.id)
    end

    include_examples 'require logged in user'
    include_examples 'require a question bank editor'

    context 'with a logged in user who is a question bank editor' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
      end

      it 'finds and assigns the topic with the specified id and renders ' \
         'the show view' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template :show

        expect(assigns(:question_bank_topic)).to eq(topic)

        expect(assigns(:active_banks)).to eq([active_question_bank, pending_question_bank])

        expect(assigns(:inactive_banks)).to eq([inactive_question_bank])
      end
    end
  end

  describe 'GET /topic_mappings' do
    let(:topic) { create(:question_bank_topic) }
    let(:language_code) { 'es' }
    let(:program_1) do
      create(:program, title: 'Title B', language_code: language_code)
    end
    let(:program_2) do
      create(:program, title: 'Title A', language_code: language_code)
    end
    let(:concept_1) { create(:concept, program: program_1) }
    let(:concept_2) { create(:concept, program: program_2) }

    before do
    end

    def do_request
      get topic_mappings_question_bank_topic_path(id: topic.id)
    end

    include_examples 'require logged in user'
    include_examples 'require a question bank editor'

    context 'with a logged in user who is a question bank editor' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
      end

      it 'finds and assigns the topic with the specified id and renders ' \
         'the show view' do
        mapping_1 = create(
          :question_bank_topics_concept,
          concept: concept_1,
          question_bank_topic: topic
        )

        mapping_2 = create(
          :question_bank_topics_concept,
          concept: concept_2,
          question_bank_topic: topic
        )

        do_request

        expect(response).to be_ok

        expect(response).to render_template :topic_mappings

        expect(assigns(:question_bank_topic)).to eq(topic)

        # Mapping 2 comes first because of the sort on program title.
        expect(assigns(:mappings)).to eq([mapping_2, mapping_1])
      end
    end
  end
end
