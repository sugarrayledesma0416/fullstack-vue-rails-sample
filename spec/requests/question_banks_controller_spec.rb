require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'
require 'requests/shared_question_bank_editor_examples'

describe QuestionBanksController do
  include ActionDispatch::TestProcess::FixtureFile

  let(:user) { create(:user) }
  let(:language_code) { 'es' }
  let(:program) { create(:program, language_code: language_code) }
  let(:concept) { create(:concept, program: program) }
  let(:topic) { create(:question_bank_topic) }

  before do
    create(
      :question_bank_topics_concept,
      concept: concept,
      question_bank_topic: topic
    )
  end

  describe 'GET /new' do
    def do_request
      get(
        new_question_bank_topic_question_bank_path(
          question_bank_topic_id: topic.id
        )
      )
    end

    include_examples 'require logged in user'
    include_examples 'require a question bank editor'

    context 'with a logged in user who is a question bank editor' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
      end

      it 'renders a new view' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template :new

        expect(assigns(:topic)).to eq(topic)

        question_bank = assigns(:question_bank)
        expect(question_bank).to be_a(QuestionBank)
        expect(question_bank).not_to be_persisted
      end
    end
  end

  describe 'GET /edit' do
    let(:user) { create(:user) }
    let(:filename) { 'file.csv' }
    let(:question_bank_topic) { create(:question_bank_topic) }

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

    def do_request
      get(
        edit_question_bank_topic_question_bank_path(
          question_bank_topic_id: topic.id,
          id: question_bank.id
        )
      )
    end

    include_examples 'require logged in user'
    include_examples 'require a question bank editor'

    context 'with a logged in user who is a question bank editor,' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
      end

      it 'assigns the question bank with the specified id and renders the edit view' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template :edit

        expect(assigns(:topic)).to eq(topic)

        question_bank = assigns(:question_bank)
        expect(question_bank).to be_a(QuestionBank)
      end
    end
  end

  describe 'POST /create' do
    let(:virus_name) { 'my_bad_virus' }
    let(:infected_file_params) { { infected: 'true', virus_name: virus_name } }

    let(:fixture_filename) do
      'question_bank_multiple_choice_3_choices_windows-1252.csv'
    end

    let(:fixture_file) { "spec/fixtures/csv/#{fixture_filename}" }
    let(:raw_csv) { File.read(fixture_file, encoding: 'ASCII-8BIT') }
    let(:upload) { fixture_file_upload(fixture_file, 'text/csv') }

    def do_request(override_params = {})
      post(
        question_bank_topic_question_banks_path(
          question_bank_topic_id: topic.id
        ),
        params: { uploaded_file: upload }.merge(override_params)
      )
    end

    include_examples 'require logged in user'
    include_examples 'require a question bank editor'

    context 'with a logged in user who is a question bank editor' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
      end

      it 'creates a question bank and redirects to the activity show view ' \
         'for the new question bank, with a valid uploaded multiple choice ' \
         'file' do
        do_request

        question_bank = QuestionBank.last

        expect(response).to redirect_to(
          section_activity_path(id: question_bank.id, section_id: 0, popup: 1)
        )

        expect(flash[:success]).to eq(
          'Question Bank was successfully created'
        )

        title = 'Elegir - Multiple choice'

        expect(question_bank).to have_attributes(
          activity_type: 'exam',
          question_bank_topic_id: topic.id,
          title: title
        )

        revision = question_bank.question_bank_revisions.last
        expect(revision).to have_attributes(
          changed_by_id: user.id,
          upload_filename: fixture_filename,
          uploaded_csv: raw_csv
        )

        content_object = question_bank.content_object
        expect(content_object).to be_a(
          MaestroActivityEngine::ActivityContent::ExamContent
        )

        sub_activities = content_object.activities
        expect(sub_activities.size).to eq(1)
        multiple_choice_activity = sub_activities.first

        expect(multiple_choice_activity.activity_type).to eq('multiple_choice')
        expect(multiple_choice_activity.items.size).to eq(16)

        exam_reference = multiple_choice_activity.items.first
        expect(exam_reference.header.text).to eq(title)
        expect(exam_reference.body.text).to eq(
          'Complete each sentence with the correct option.'
        )

        question_1 = multiple_choice_activity.items[1]
        expect(question_1.prompt.text).to eq('A Pedro')
        expect(question_1.choices.size).to eq(3)
      end

      it 'creates a question bank and redirects to the activity show view ' \
         'for the new question bank, with a valid uploaded multiple choice ' \
         'file with utf8 encoding' do
        mc_utf8_upload = fixture_file_upload(
          'spec/fixtures/csv/question_bank_multiple_choice_3_choices_utf-8.csv',
          'text/csv'
        )
        do_request(uploaded_file: mc_utf8_upload)

        question_bank = QuestionBank.last

        expect(response).to redirect_to(
          section_activity_path(id: question_bank.id, section_id: 0, popup: 1)
        )

        expect(flash[:success]).to eq(
          'Question Bank was successfully created'
        )

        title = 'Elegir - Multiple choice'

        expect(question_bank).to have_attributes(
          activity_type: 'exam',
          question_bank_topic_id: topic.id,
          title: title
        )

        content_object = question_bank.content_object
        expect(content_object).to be_a(
          MaestroActivityEngine::ActivityContent::ExamContent
        )

        sub_activities = content_object.activities
        expect(sub_activities.size).to eq(1)
        multiple_choice_activity = sub_activities.first

        expect(multiple_choice_activity.activity_type).to eq('multiple_choice')
        expect(multiple_choice_activity.items.size).to eq(16)

        exam_reference = multiple_choice_activity.items.first
        expect(exam_reference.header.text).to eq(title)
        expect(exam_reference.body.text).to eq(
          'Complete each sentence with the correct option.'
        )

        question_1 = multiple_choice_activity.items[1]
        expect(question_1.prompt.text).to eq('A Pedro')
        expect(question_1.choices.size).to eq(3)
      end

      it 'creates a question bank and redirects to the activity show view ' \
         'for the new question bank, with a valid uploaded multiple choice ' \
         'binary file' do
        mc_same_upload = fixture_file_upload(
          'spec/fixtures/csv/question_bank_multiple_choice_same_windows-1252.csv',
          'text/csv'
        )
        do_request(uploaded_file: mc_same_upload)

        question_bank = QuestionBank.last

        expect(response).to redirect_to(
          section_activity_path(id: question_bank.id, section_id: 0, popup: 1)
        )

        expect(flash[:success]).to eq(
          'Question Bank was successfully created'
        )

        title = 'Indicar - ¿Lógico o ilógico?'

        expect(question_bank).to have_attributes(
          activity_type: 'exam',
          question_bank_topic_id: topic.id,
          title: title
        )

        content_object = question_bank.content_object
        expect(content_object).to be_a(
          MaestroActivityEngine::ActivityContent::ExamContent
        )

        sub_activities = content_object.activities
        expect(sub_activities.size).to eq(1)
        multiple_choice_activity = sub_activities.first

        expect(multiple_choice_activity.activity_type).to eq('multiple_choice')
        expect(multiple_choice_activity.items.size).to eq(16)

        exam_reference = multiple_choice_activity.items.first
        expect(exam_reference.header.text).to eq(title)
        expect(exam_reference.body.children.to_s.html_decode).to eq(
          'Indicate whether each statement is <b>lógico</b> or <b>ilógico</b>.'
        )

        question_1 = multiple_choice_activity.items[1]
        expect(question_1.prompt.text).to eq(
          'Los estudiantes juegan fútbol en el laboratorio.'
        )
        expect(question_1.choices.size).to eq(2)
      end

      it 'creates a question bank and redirects to the activity show view for ' \
         'the new question bank, with a valid uploaded fill-in-the-blanks file' do
        fill_in_the_blanks_upload = fixture_file_upload(
          'spec/fixtures/csv/question_bank_fill_in_the_blanks_windows-1252.csv',
          'text/csv'
        )
        do_request(uploaded_file: fill_in_the_blanks_upload)

        question_bank = QuestionBank.last

        expect(response).to redirect_to(
          section_activity_path(id: question_bank.id, section_id: 0, popup: 1)
        )

        expect(flash[:success]).to eq(
          'Question Bank was successfully created'
        )

        title = 'Completar - Fill in the blanks'

        expect(question_bank).to have_attributes(
          activity_type: 'exam',
          question_bank_topic_id: topic.id,
          title: title
        )

        content_object = question_bank.content_object
        expect(content_object).to be_a(
          MaestroActivityEngine::ActivityContent::ExamContent
        )

        sub_activities = content_object.activities
        expect(sub_activities.size).to eq(1)
        fill_in_the_blanks_activity = sub_activities.first

        expect(fill_in_the_blanks_activity.activity_type).to eq('fill_in_the_blanks')
        expect(fill_in_the_blanks_activity.items.size).to eq(32)

        exam_reference = fill_in_the_blanks_activity.items.first
        expect(exam_reference.header.text).to eq(title)
        expect(exam_reference.body.children.to_s.html_decode).to eq(
          'Complete each sentence with the appropiate word.'
        )

        question_1 = fill_in_the_blanks_activity.items[1]
        expect(question_1.prompt.node.children.to_s.html_decode).to eq(
          'La profesora de <wol ref="1"/> enseña las reglas de gramática.'
        )
        expect(question_1.wols.size).to eq(1)
        expect(question_1.wols.first.answers).to contain_exactly(
          'español', 'inglés', 'lenguas extranjeras'
        )
      end

      it 'creates a question bank and redirects to the activity show view ' \
         'for the new question bank, with a valid uploaded open ended file' do
        open_ended_upload = fixture_file_upload(
          'spec/fixtures/csv/question_bank_open_ended_windows-1252.csv',
          'text/csv'
        )
        do_request(uploaded_file: open_ended_upload)

        question_bank = QuestionBank.last

        expect(response).to redirect_to(
          section_activity_path(id: question_bank.id, section_id: 0, popup: 1)
        )

        expect(flash[:success]).to eq(
          'Question Bank was successfully created'
        )

        title = 'Escribir - Open ended'

        expect(question_bank).to have_attributes(
          activity_type: 'exam',
          question_bank_topic_id: topic.id,
          title: title
        )

        content_object = question_bank.content_object
        expect(content_object).to be_a(
          MaestroActivityEngine::ActivityContent::ExamContent
        )

        sub_activities = content_object.activities
        expect(sub_activities.size).to eq(1)
        open_ended_activity = sub_activities.first

        expect(open_ended_activity.activity_type).to eq('open_ended')
        expect(open_ended_activity.items.size).to eq(6)

        exam_reference = open_ended_activity.items.first
        expect(exam_reference.header.text).to eq(title)
        expect(exam_reference.body.children.to_s.html_decode).to eq(
          'Write your answer to the prompts below.'
        )

        question_1 = open_ended_activity.items[1]
        expect(question_1.prompt.children.to_s).to eq(
          'You are meeting a classmate for the first time. Write five ' \
          'questions you would ask him/her and then five answers he/she ' \
          'would give you. Include at least four <b>-ar</b> verbs in ' \
          'present tense.'
        )
      end

      it 'creates a question bank and redirects to the activity show view ' \
         'for the new question bank, with a valid uploaded drop-down ' \
         'file' do
        drop_down_upload = fixture_file_upload(
          'spec/fixtures/csv/question_bank_drop_down_3_choices_utf-8.csv',
          'text/csv'
        )
        do_request(uploaded_file: drop_down_upload)

        question_bank = QuestionBank.last

        expect(response).to redirect_to(
          section_activity_path(id: question_bank.id, section_id: 0, popup: 1)
        )

        expect(flash[:success]).to eq(
          'Question Bank was successfully created'
        )

        title = 'Completar - Drop Down'

        expect(question_bank).to have_attributes(
          activity_type: 'exam',
          question_bank_topic_id: topic.id,
          title: title
        )

        content_object = question_bank.content_object
        expect(content_object).to be_a(
          MaestroActivityEngine::ActivityContent::ExamContent
        )

        sub_activities = content_object.activities
        expect(sub_activities.size).to eq(1)
        drop_down_activity = sub_activities.first

        expect(drop_down_activity.activity_type).to eq('drop_down')
        expect(drop_down_activity.items.size).to eq(6)

        exam_reference = drop_down_activity.items.first
        expect(exam_reference.header.text).to eq(title)
        expect(exam_reference.body.text).to eq(
          'Complete each sentence with the correct option.'
        )

        question_1 = drop_down_activity.items[1]
        expect(question_1.prompt.node.children.to_s.html_decode).to eq(
          'A Pedro <wol ref="1"/>'
        )
        expect(question_1.menus.size).to eq(1)
        choices = question_1.menus.first.options
        expect(
          choices.map { |choice| [choice.text, choice.is_correct] }
        ).to contain_exactly(
          ['le gustan los cómics', true],
          ['nos gustan los cómics', false],
          ['me gustan los cómics', false]
        )
      end

      it 'does not create a new question bank when a file infected with ' \
         'a virus is uploaded' do
        expect do
          do_request(uploaded_file: infected_file_params)
        end.not_to change(QuestionBank, :count)

        expect(response).to be_ok

        expect(response).to render_template :new

        expect(flash[:error]).to eq(
          'Question Bank creation failed'
        )

        expect(assigns(:topic)).to eq(topic)

        question_bank = assigns(:question_bank)
        expect(question_bank).to be_a(QuestionBank)
        expect(question_bank).not_to be_persisted

        expect(question_bank.errors.full_messages).to contain_exactly(
          /infected with the virus '#{virus_name}'/
        )
      end

      it 'renders the new view and displays error messages if no file ' \
         'is uploaded' do
        expect do
          do_request(uploaded_file: nil)
        end.not_to change(QuestionBank, :count)

        expect(response).to be_ok

        expect(response).to render_template :new

        expect(flash[:error]).to eq(
          'Question Bank creation failed'
        )

        expect(assigns(:topic)).to eq(topic)

        question_bank = assigns(:question_bank)
        expect(question_bank).to be_a(QuestionBank)
        expect(question_bank).not_to be_persisted

        expect(question_bank.errors.full_messages).to contain_exactly(
          'No CSV file was provided'
        )
      end
    end
  end

  describe 'PATCH /update' do
    let(:virus_name) { 'my_bad_virus' }
    let(:infected_file_params) { { infected: 'true', virus_name: virus_name } }

    let(:new_fixture_filename) do
      'question_bank_fill_in_the_blanks_windows-1252.csv'
    end

    let(:new_fixture_file) { "spec/fixtures/csv/#{new_fixture_filename}" }
    let(:new_raw_csv) { File.read(new_fixture_file, encoding: 'ASCII-8BIT') }
    let(:new_upload) { fixture_file_upload(new_fixture_file, 'text/csv') }

    let(:old_json) do
      File.read(
        File.join('spec', 'fixtures', 'json', 'open_ended_question_bank.json')
      )
    end

    let(:original_attrs) do
      {
        content_json: old_json,
        question_bank_topic: topic,
        title: 'a title'
      }
    end

    def do_request(topic, question_bank, override_params = {})
      patch(
        question_bank_topic_question_bank_path(
          question_bank_topic_id: topic.id,
          id: question_bank.id
        ),
        params: { uploaded_file: new_upload }.merge(override_params)
      )
    end

    context 'with a logged in user who is a question bank editor,' do
      before do
        log_in_user(user)
        user.roles.create!(name: Role::QUESTION_BANK_EDITOR)
      end

      it 'updates the question bank record specified' do
        question_bank = QuestionBank.create!(original_attrs)
        expect do
          do_request(topic, question_bank)
        end.to change(QuestionBankRevision, :count)

        revision = question_bank.question_bank_revisions.last
        expect(revision).to have_attributes(
          changed_by_id: user.id,
          upload_filename: new_fixture_filename,
          uploaded_csv: new_raw_csv
        )

        expect(flash[:success]).to eq(
          'Revision was successfully created'
        )

        question_bank.reload
        expect(question_bank).to have_attributes(
          question_bank_revision_id: revision.id,
          title: 'Completar - Fill in the blanks'
        )
      end

      it 'does not update the question bank when a file infected with ' \
         'a virus is uploaded' do
        question_bank = QuestionBank.create!(original_attrs)
        expect do
          do_request(topic, question_bank, uploaded_file: infected_file_params)
        end.not_to change(QuestionBankRevision, :count)

        expect(response).to be_ok

        expect(response).to render_template :edit

        expect(flash[:error]).to eq(
          'Revision creation failed'
        )

        expect(assigns(:topic)).to eq(topic)

        question_bank = assigns(:question_bank)
        expect(question_bank).to be_a(QuestionBank)
        expect(question_bank).to have_attributes original_attrs

        expect(question_bank.errors.full_messages).to contain_exactly(
          /infected with the virus '#{virus_name}'/
        )
      end

      it 'renders the edit view and displays error messages if no file ' \
         'is uploaded' do
        existing_question_bank = QuestionBank.create!(original_attrs)
        expect do
          do_request(topic, existing_question_bank, uploaded_file: nil)
        end.not_to change(QuestionBankRevision, :count)

        expect(response).to be_ok

        expect(response).to render_template :edit

        expect(flash[:error]).to eq(
          'Revision creation failed'
        )

        expect(assigns(:topic)).to eq(topic)

        question_bank = assigns(:question_bank)
        expect(question_bank).to be_a(QuestionBank)
        expect(question_bank).to have_attributes(original_attrs)

        expect(question_bank.errors.full_messages).to contain_exactly(
          'No CSV file was provided'
        )
      end
    end
  end
end
