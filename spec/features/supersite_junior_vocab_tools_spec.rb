feature 'Supersite Junior Vocabulary Tools',
        js: true, chrome: true, clear_local_storage: true, stub_js_audio: true do
  include RspecJsApiHelpers
  include RspecJsCommonHelpers
  include Capybara::Angular::DSL

  def create_units(program, count:, **args)
    unit_factory = args.delete(:unit_factory) || :unit
    Array.new(count) do |index|
      create(
        unit_factory,
        {
          media_item_id: media_items[index].id,
          program: program,
          rank: index + 1,
          use_type: 'Unit'
        }.merge(args)
      )
    end
  end

  let(:program) { create(:ss_jr_program, title: 'Supersite Junior Program') }
  let(:units) { create_units(program, count: 4, unit_factory: :unit_with_lesson) }
  let(:user) { create(:user) }
  let(:api_token) { instance_double(Maestro::ApiToken, secret: 'secret', jid: 'foo@bar.com') }
  let(:section_zero) { Section.section_zero }

  let(:media_items) do
    Array.new(4) do |i|
      create(
        :media_item_image,
        id: (500 + i),
        filename: "unit#{i + 1}_thumbnail.png"
      )
    end
  end

  before do |example|
    # Create double LicenseGroup
    license_group = instance_double(
      Maestro::LicenseGroup,
      id: 1,
      site_function?: true,
      site_function_name: 'my_vocabulary'
    )

    # Create a user license that points to this license group
    user_license = instance_double(
      Maestro::UserLicense,
      license_group: license_group
    )
    allow(user_license).to receive(:expired?).and_return(true)
    # Ensure that Maestro::UserLicense.all_for_user_and_program returns this user_license
    allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([user_license])

    # Create a LicensedContent double that has the license_group created in step 1
    licensed_content = instance_double(
      Maestro::LicensedContent,
      license_group_ids: [license_group.id]
    )
    # Ensure that Maestro::LicenseContent.find_for_user_and_program
    # returns this licensed_content double
    allow(Maestro::LicensedContent).to receive(:find_for_user_and_program)
      .and_return(licensed_content)

    initialize_client_calls_for_user(user)
    log_in_as(user) unless example.metadata[:skip_login]
  end

  scenario 'As a Student enrolled in a course, I see the default unit range ' \
           'for the course when I visit the vocab-tools units page' do
    # a lesson must have words to be visible in the words page.
    units.each do |unit|
      create(:default_vocabulary_word, topic: 'foo', lesson: unit.lessons.last)
    end
    units_in_range = [units[1], units[2]]
    course = create(
      :course,
      first_unit_id: units[1].id,
      last_unit_id: units[2].id,
      program: program
    )
    section = create(:section, course: course)
    student = create(:student)
    create(:active_enrollment, section: section, user: student)
    initialize_client_calls_for_user(student)
    log_in_as(student)

    visit(vocab_tools_units_path(program, section))

    # The units in range should be visible.
    units_in_range.each do |unit|
      expect(page).to have_selector(
        "a[href='/#{program.id}/sections/#{section.id}/vocab_tools/words?unit_id=#{unit.id}']",
        visible: :visible
      )
    end

    # TODO: View all lessons in this program" / "View only lessons for this course
  end

  scenario 'As a user, I can not see translation related options in Study Modes ' \
           'if hide translation is true ' do
    allow(Maestro::ApiToken).to receive(:fetch).and_return(api_token)
    create(
      :program_config,
      program: program,
      vocab_definition: true,
      hide_translation: true
    )

    unit = units.first
    lesson = unit.lessons.first
    create(
      :default_vocabulary_word,
      audio_paths: ['foo.mp3'],
      lesson: lesson,
      program: program,
      target: 'capitulado/a hi'
    )

    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
    find('.test-flashcards-link').click
    target_langage = program.language_name
    options = all('.test-study-mode-select option').map(&:text)
    option_1 = "#{target_langage} to Notes"
    option_2 = "Notes to #{target_langage}"
    expect(options).to eq([option_1, option_2])
  end

  scenario 'As a user, I can see translation related options in Study Modes ' \
           'if hide translation is false ' do
    allow(Maestro::ApiToken).to receive(:fetch).and_return(api_token)
    create(
      :program_config,
      program: program,
      vocab_definition: true,
      hide_translation: false
    )

    unit = units.first
    lesson = unit.lessons.first
    create(
      :default_vocabulary_word,
      audio_paths: ['foo.mp3'],
      lesson: lesson,
      program: program,
      target: 'capitulado/a hi'
    )

    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
    find('.test-flashcards-link').click
    target_langage = program.language_name
    options = all('.test-study-mode-select option').map(&:text)
    option_1 = "#{target_langage} to English"
    option_2 = "English to #{target_langage}"
    option_3 = "Definition to #{target_langage}"
    expect(options).to eq([option_1, option_2, option_3])
  end

  scenario 'As a user, I see audio controls only when I view the flashcard for ' \
           'a word with audio' do
    allow(Maestro::ApiToken).to receive(:fetch).and_return(api_token)

    unit = units.first
    lesson = unit.lessons.first
    vocab_word = create(:default_vocabulary_word,
                        audio_paths: ['foo.mp3'],
                        lesson: lesson,
                        program: program,
                        target: 'capitulado/a hi')

    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
    find('.test-flashcards-link').click
    # Select target->English mode
    select 'to English', from: 'study_mode_select'
    find('.test-start-activity').click

    # The audio controls should be present.
    expect(page).to have_selector('.test-flashcard-audio-controls')

    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
    find('.test-flashcards-link').click
    # Select English->target mode
    select 'English to', from: 'study_mode_select'
    find('.test-start-activity').click

    # In 'English to' mode audio controls should not be present on front side
    expect(page).not_to have_selector('.test-flashcard-audio-controls')

    # Flip the card
    find('.test-flashcard').click
    expect(page).to have_selector('.test-flashcard-audio-controls')

    # The audio controls should be present.
    expect(page).to have_selector('.test-flashcard-audio-controls')

    # Remove the audio_paths
    vocab_word.update!(audio_paths: [])
    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
    find('.test-flashcards-link').click
    find('.test-start-activity').click
    # The audio controls should not be present.
    expect(page).not_to have_selector('.test-flashcard-audio-controls')
  end

  scenario 'User can see a list of words organized by lesson' do
    allow(Maestro::ApiToken).to receive(:fetch).and_return(api_token)
    unit = create_units(program, count: 1, unit_factory: :unit_with_lessons).first
    lesson = unit.lessons.first
    create(:default_vocabulary_word, program: program, lesson: lesson, target: 'capitulado/a hi')

    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))

    # one table for each lesson
    expect(all('.test-table-vocab-tools-lesson-words').count).to eq(2)

    expect(page).to have_selector(
      '.test-table-vocab-tools-lesson-words td',
      text: 'capitulado/a hi'
    )
  end

  context 'when a user can perform CRUD operation on user defined words' do
    before do
      create(
        :program_config,
        program: program,
        vocab_definition: true,
        hide_translation: true
      )
    end

    scenario 'User can see a Columns "English" and "Notes" ' \
      'if hide translation is true ' do
      allow(Maestro::ApiToken).to receive(:fetch).and_return(api_token)

      program.update!(language_code: 'en')
      unit = create_units(program, count: 1, unit_factory: :unit_with_lessons).first
      lesson = unit.lessons.first
      create(
        :default_vocabulary_word,
        program: program,
        lesson: lesson,
        target: 'some word',
        definition: 'some definition'
      )

      visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))

      # Expectations for table columns
      expect(page).to have_selector('.test-vocab-target-language', text: 'English')
      expect(page).to have_no_selector('.test-vocab-translation-language')
      expect(page).to have_selector('.test-vocab-th-definition', text: 'Notes')

      # Expectations for word data
      expect(page).to have_selector('td .test-target-word', text: 'some word')
      expect(page).to have_no_selector('td .test-translation-word')
      expect(page).to have_selector('td .test-definition-word', text: 'some definition')
    end

    scenario 'As a User I can add a custom vocab word' do
      unit = units.first
      create(:default_vocabulary_word, program: program, lesson: unit.lessons.last)
      target = 'hola'
      definition = 'hello'

      # Execution
      visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
      find(".test-lesson-#{unit.lessons.last.id}-add-word").click
      find(".test-lesson-#{unit.lessons.last.id}-new-L2").set(target)
      find(".test-lesson-#{unit.lessons.last.id}-new-definition").set(definition)
      find('.test-user-word-add-save', visible: true).click
      WaitForAjax

      # Expectations
      expect(page).to have_selector('.test-target-word', text: target)
      expect(page).to have_selector('.test-definition-word', text: definition)

      result = UserDefinedWord.where(user_id: user).first
      expect(result).not_to be_nil
      expect(result.target).to eq(target)
      expect(result.definition).to eq(definition)

      # Execution
      visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))

      # Expectations
      expect(page).to have_selector('.test-target-word', text: target)
      expect(page).to have_selector('.test-definition-word', text: definition)
    end

    scenario 'As a User I must provide both target and notes to add a custom vocab word ' \
      'if hide translation is true ' do
      unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first
      lesson = unit.lessons.first
      create(:default_vocabulary_word, program: program, lesson: lesson)
      new_target = 'new target'
      new_definition = 'new definition'

      # Execution
      visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
      find(".test-lesson-#{lesson.id}-add-word").click
      find(".test-lesson-#{lesson.id}-new-L2").set(new_target)
      find('.test-user-word-add-save', visible: true).click

      # Expectations
      result = UserDefinedWord.where(user_id: user).first
      expect(result).to be_nil

      expect(page).to have_no_selector('.test-target-word', text: new_target)

      # Execution
      visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
      find(".test-lesson-#{lesson.id}-add-word").click
      find(".test-lesson-#{lesson.id}-new-definition").set(new_definition)
      find('.test-user-word-add-save', visible: true).click

      # Expectations
      result = UserDefinedWord.where(user_id: user).first
      expect(result).to be_nil

      expect(page).to have_no_selector('.test-definition-word', text: new_definition)
    end

    scenario 'As a User I can update a custom vocab word' do
      unit = units.first
      create(:default_vocabulary_word, program: program, lesson: unit.lessons.last)
      old_target = 'hola'
      old_definition = 'hello'
      new_target = 'bueno'
      new_definition = 'awesome'

      word_to_update = create(
        :user_defined_word,
        lesson: unit.lessons.last,
        program: program,
        target: old_target,
        definition: old_definition,
        user: user
      )

      visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
      WaitForAjax
      find('.test-user-word-edit .test-music-icon-edit', visible: true).click
      find(".test-edit-#{word_to_update.id}-L2").set(new_target)
      find(".test-edit-#{word_to_update.id}-definition").set(new_definition)
      find('.test-user-word-edit-save', visible: true).click
      WaitForAjax
      sleep 1 # sleep to give time to the database to write updated values

      # Expectations
      word_to_update.reload
      expect(word_to_update.target).to eq(new_target)
      expect(word_to_update.definition).to eq(new_definition)
      expect(page).to have_selector('.test-target-word', text: new_target)
      expect(page).to have_selector('.test-definition-word', text: new_definition)
    end

    scenario 'As a User I can delete a custom vocab word' do
      unit = units.first
      create(:default_vocabulary_word, program: program, lesson: unit.lessons.last)
      target = 'hola'
      definition = 'hello'

      word_to_delete = create(
        :user_defined_word,
        lesson: unit.lessons.last,
        program: program,
        target: target,
        definition: definition,
        user: user
      )
      visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
      find('.test-user-word-edit .test-music-icon-edit', visible: true).click
      find('.test-user-word-delete', visible: true).click
      find('.test-confirm-yes', visible: true).click
      WaitForAjax
      sleep 1 # sleep to give time to the database to delete the word.

      expect(UserDefinedWord.where(id: word_to_delete.id)).to be_empty
      expect(page).not_to have_selector('.test-target-word', text: target)
      expect(page).not_to have_selector('.test-definition-word', text: definition)
    end
  end
end
