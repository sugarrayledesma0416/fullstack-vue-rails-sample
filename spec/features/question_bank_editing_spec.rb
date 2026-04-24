feature 'Question Bank Editing', js: true, chrome: true do
  include RspecJsCommonHelpers

  let(:editor) { create(:user) }
  let(:program_1) { create(:program) }
  let(:program_2) { create(:program) }
  let(:p1_unit) { create(:unit_with_lesson, program: program_1) }
  let(:p2_unit) { create(:unit_with_lesson, program: program_2) }

  let(:p1_lesson) { p1_unit.lessons.first }
  let(:p2_lesson) { p2_unit.lessons.first }

  let(:p1_strand) { create(:toc_entry) }
  let(:p2_strand) { create(:toc_entry) }

  let(:p1_concept) do
    create(
      :concept,
      id: p1_strand.location,
      lesson: p1_lesson,
      name: p1_strand.title,
      program: program_1
    )
  end

  let(:p2_concept) do
    create(
      :concept,
      id: p2_strand.location,
      lesson: p2_lesson,
      name: p2_strand.title,
      program: program_2
    )
  end

  let(:topic_1) { create(:question_bank_topic, name: 'Topic 1',
                                               language: 'English',
                                               level: 'Intro') }
  let(:topic_2) { create(:question_bank_topic, name: 'Topic 2',
                                               language: 'Spanish',
                                               level: 'Intro 2') }

  let(:json) do
    File.read(
      File.join('spec', 'fixtures', 'json', 'open_ended_question_bank.json')
    )
  end

  let!(:question_bank) do
    create(
      :question_bank,
      changed_by_id: editor.id,
      content_json: json,
      question_bank_topic: topic_1,
      upload_filename: 'fake_file.csv'
    )
  end

  before do
    p1_lesson.toc_entries = [p1_strand]
    p1_lesson.save!

    p2_lesson.toc_entries = [p2_strand]
    p2_lesson.save!

    create(
      :question_bank_topics_concept,
      concept: p1_concept,
      question_bank_topic: topic_1
    )

    create(
      :question_bank_topics_concept,
      concept: p2_concept,
      question_bank_topic: topic_1
    )

    create(
      :question_bank_topics_concept,
      concept: p1_concept,
      question_bank_topic: topic_2
    )

    # initialize_program_access_client_calls_for_instructor(editor, program)
    # give_user_access_to_program(editor, program)
    editor.roles.create!(name: Role::QUESTION_BANK_EDITOR)
    log_in_as(editor)
  end

  scenario 'As a question bank editor, I can upload a question bank ' \
           'and associate it with a topic' do
    purpose 'I can view a list of topics, with a link to view each topic' do
      visit question_bank_topics_path

      expect(page).to have_link(topic_1.name)
      expect(page).to have_link(topic_2.name)
    end

    purpose 'I can view a list of topics filtered by language' do
      visit question_bank_topics_path
      select('english', from: 'select-language').select_option
      select('Select', from: 'select-level').select_option
      click_button('Filter')

      expect(page).to have_selector('th', text: topic_1.name, visible: true)
      expect(page).to have_selector('th', text: topic_2.name, visible: false)
      click_button('Clear')
    end

    purpose 'I can view a list of topics filtered by level' do
      visit question_bank_topics_path
      select('Select', from: 'select-language').select_option
      select('intro 2', from: 'select-level').select_option
      click_button('Filter')

      expect(page).to have_selector('th', text: topic_1.name, visible: false)
      expect(page).to have_selector('th', text: topic_2.name, visible: true)

      click_button('Clear')
    end

    purpose 'I can view a list of topics filtered by language and level' do
      visit question_bank_topics_path
      select('english', from: 'select-language').select_option
      select('intro 2', from: 'select-level').select_option
      click_button('Filter')

      expect(page).to have_selector('th', text: topic_1.name, visible: false)
      expect(page).to have_selector('th', text: topic_2.name, visible: false)

      click_button('Clear')
    end

    purpose 'I can view a topic and see a list of question banks for ' \
            'that topic' do
      click_link(topic_1.name)

      within(".test-question-bank-#{question_bank.id}") do
        expect(page).to have_link(question_bank.title)
        expect(page).to have_selector('td', text: 'List')
        expect(page).to have_selector('td', text: editor.full_name)
      end
    end
  end
end
