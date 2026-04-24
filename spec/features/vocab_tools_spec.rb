feature 'Vocabulary Tools',
  js: true, chrome: true, clear_local_storage: true, stub_js_audio: true do
  include RspecJsApiHelpers
  include RspecJsCommonHelpers
  include Capybara::Angular::DSL

  words_link_selector_template = "a[href='/%{program_id}/sections/%{section_id}/vocab_tools/words?unit_id=%{unit_id}']"
  view_all_lessons_text = 'View all lessons in this program'
  view_unit_range_text = 'View only lessons for this course'

  def create_program(args = {})
    program = create(
      :program,
      { title: 'I am the program' }.merge(args)
    )
    ProgramConfig.create!(
      program_id: program.id,
      creator_id: create(:user).id,
      vocab_definition: false,
      vocab_words: true,
      vocab_tools: 'override vocab tools title'
    )
    program
  end

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

  let(:user) { create(:user) }
  let(:program_setting) {
    instance_double(
      ProgramSettings,
      vocab_tools_label: 'Vocabulary Tools',
      has_activities?: true,
      has_assessment?: false,
      has_vocab_words?: false,
      has_vocab_tools?: true,
      content_menu_additional_entries: [],
      share_to_portfolio?: false,
      supported_standard_sets: []
    )
  }
  let(:program) { create_program }
  let(:course) { create(:course, program:) }
  let(:section) { create(:section, course:) }
  let(:section_zero) { Section.section_zero }

  let(:api_token) { instance_double(Maestro::ApiToken, secret: 'secret', jid: 'foo@bar.com') }

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
    if example.metadata[:no_user_licence]
      # Ensure that Maestro::UserLicense.all_for_user_and_program does not
      # return any user_license (this is to prevent access)
      allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([])
    else
      # Create a user license that points to this license group
      user_license = instance_double(
        Maestro::UserLicense,
        license_group: license_group
      )
      allow(user_license).to receive(:expired?).and_return(true)
      # Ensure that Maestro::UserLicense.all_for_user_and_program returns this user_license
      allow(Maestro::UserLicense).to receive(:all_for_user_and_program).and_return([user_license])
    end
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

  scenario 'User can see a list of units in the program', log_in: true do
    units = create_units(program, count: 4, unit_factory: :unit_with_lesson)

    visit(vocab_tools_units_path(program, section_zero))

    expect(page).to have_link(
      'Return to Dashboard',
      href: no_section_student_dashboard_path(section_zero, program)
    )

    units.each do |unit|
      expect(page).to have_link(unit.name, href: vocab_tools_words_path(program, section_zero, unit_id: unit.id))
      expect(page).to have_xpath("//img[@src='#{unit.media_item.public_filename}']")
    end
  end

  scenario 'User can see a list of words organized by lesson' do
    allow(Maestro::ApiToken).to receive(:fetch).and_return(api_token)
    unit = create_units(program, count: 1, unit_factory: :unit_with_lessons).first
    lesson = unit.lessons.first
    create(:default_vocabulary_word, program: program, lesson: lesson, target: 'capitulado/a hi')

    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))

    # one table for all lessons
    expect(all('.test-table-vocab-tools-words').count).to eq(2)

    expect(page).to have_link(
      'Return to Dashboard',
      href: no_section_student_dashboard_path(section_zero, program)
    )

    expect(page).to have_selector('.test-table-vocab-tools-words td', text: 'capitulado/a hi')
  end

  scenario 'As a User I can add a custom vocab word' do
    program = create_program(id: 79)
    unit = create_units(program, count: 1).first
    lesson = create(:lesson, unit: unit)
    create(:default_vocabulary_word, program: program, lesson: lesson)
    target = 'hola'
    translation = 'hello'

    # Execution
    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
    find(".test-lesson-#{lesson.id}-add-word").click
    find(".test-lesson-#{lesson.id}-new-L2").set(target)
    find(".test-lesson-#{lesson.id}-new-L1").set(translation)
    find('.test-user-word-add-save', visible: :visible).click
    WaitForAjax

    # Expectations
    expect(page).to have_selector('.test-target-word', text: target)
    expect(page).to have_selector('.test-translation-word', text: translation)

    result = UserDefinedWord.where(user_id: user).first
    expect(result).not_to be_nil
    expect(result.target).to eq(target)
    expect(result.translation).to eq(translation)

    # Execution
    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))

    # Expectations
    expect(page).to have_selector('.test-target-word', text: target)
    expect(page).to have_selector('.test-translation-word', text: translation)
  end

  scenario 'As a User I must provide both target and translation to add a custom vocab word' do
    unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first
    lesson = unit.lessons.first
    create(:default_vocabulary_word, program: program, lesson: lesson)
    target = 'adios'
    translation = 'goodbye'

    # Execution
    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
    find(".test-lesson-#{lesson.id}-add-word").click
    find(".test-lesson-#{lesson.id}-new-L2").set(target)
    find('.test-user-word-add-save', visible: :visible).click
    WaitForAjax

    # Expectations
    result = UserDefinedWord.where(user_id: user).first
    expect(result).to be_nil

    expect(page).not_to have_selector('.test-target-word', text: target, visible: true)

    # Execution
    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
    find(".test-lesson-#{lesson.id}-add-word").click
    find(".test-lesson-#{lesson.id}-new-L1").set(translation)
    find('.test-user-word-add-save', visible: :visible).click
    WaitForAjax

    # Expectations
    result = UserDefinedWord.where(user_id: user).first
    expect(result).to be_nil

    expect(page).not_to have_selector('.test-translation-word', text: translation, visible: true)
  end

  scenario 'As a User I can update a custom vocab word' do
    unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first
    lesson = unit.lessons.first
    create(:default_vocabulary_word, program: program, lesson: lesson)
    old_target = 'hola'
    old_translation = 'hello'
    new_target = 'bueno'
    new_translation = 'awesome'

    word_to_update = create(:user_defined_word,
                            lesson: lesson,
                            program: program,
                            target: old_target,
                            translation: old_translation,
                            user: user
                           )

    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
    WaitForAjax
    find('.test-user-word-edit .test-music-icon-edit', visible: :visible).click
    find(".test-edit-#{word_to_update.id}-L2").set(new_target)
    find(".test-edit-#{word_to_update.id}-L1").set(new_translation)
    find('.test-user-word-edit-save', visible: :visible).click
    WaitForAjax
    sleep 1 # sleep to give time to the database to te written

    # Expectations
    word_to_update.reload
    expect(word_to_update.target).to eq(new_target)
    expect(word_to_update.translation).to eq(new_translation)
    expect(page).to have_selector('.test-target-word', text: new_target)
    expect(page).to have_selector('.test-translation-word', text: new_translation)
  end

  scenario 'As a User I can delete a custom vocab word' do
    unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first
    lesson = unit.lessons.first
    create(:default_vocabulary_word, program: program, lesson: lesson)
    target = 'hola'
    translation = 'hello'

    word_to_delete = create(
      :user_defined_word,
      lesson: lesson,
      program: program,
      target: target,
      translation: translation,
      user: user
    )

    visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
    find('.test-user-word-edit .test-music-icon-edit', visible: :visible).click
    find('.test-user-word-delete', visible: :visible).click
    find('.test-confirm-yes', visible: :visible).click
    WaitForAjax
    sleep 1 # sleep to give time to the database to te written

    expect(UserDefinedWord.where(id: word_to_delete.id)).to be_empty
    expect(page).not_to have_selector('.test-target-word', text: target)
    expect(page).not_to have_selector('.test-translation-word', text: translation)
  end

  context 'when setting "hide translation" is true for the program' do
    before do
      allow(ProgramSettings).to receive(:new).and_return(program_setting)
      allow(program_setting).to receive(:hide_translation?).and_return(true)
      allow(program_setting).to receive(:has_vocab_definition?).and_return(true)
    end

    scenario 'User can see a Columns "English" and "Notes"' do
      allow(Maestro::ApiToken).to receive(:fetch).and_return(api_token)

      program = create_program(language_code: 'en')
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
      program = create_program(id: 79)
      unit = create_units(program, count: 1).first
      lesson = create(:lesson, unit: unit)
      create(:default_vocabulary_word, program: program, lesson: lesson)
      new_target = 'new target'
      new_definition = 'new definition'

      # Execution
      visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))
      find(".test-lesson-#{lesson.id}-add-word").click
      find(".test-lesson-#{lesson.id}-new-L2").set(new_target)
      find(".test-lesson-#{lesson.id}-new-definition").set(new_definition)
      find('.test-user-word-add-save', visible: :visible).click

      # Expectations
      expect(page).to have_selector('.test-target-word', text: new_target)
      expect(page).to have_no_selector('.test-translation-word', text: new_target)
      expect(page).to have_selector('.test-definition-word', text: new_definition)

      result = UserDefinedWord.where(user_id: user).first
      expect(result).not_to be_nil
      expect(result.target).to eq(new_target)
      # value of target is stored in translation column
      expect(result.translation).to eq(new_target)
      expect(result.definition).to eq(new_definition)

      # Execution
      visit(vocab_tools_words_path(program, section_zero, unit_id: unit.id))

      # Expectations
      expect(page).to have_selector('.test-target-word', text: new_target)
      expect(page).to have_no_selector('.test-translation-word', text: new_target)
      expect(page).to have_selector('.test-definition-word', text: new_definition)
    end

    scenario 'As a User I must provide both target and notes to add a custom vocab word' do
      unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first
      lesson = unit.lessons.first
      create(:default_vocabulary_word, program: program, lesson: lesson)
      new_target = 'new target'
      new_definition = 'new definition'

      # Execution
      visit(vocab_tools_words_path(program, section, unit_id: unit.id))
      find(".test-lesson-#{lesson.id}-add-word").click
      find(".test-lesson-#{lesson.id}-new-L2").set(new_target)
      find('.test-user-word-add-save', visible: :visible).click

      # Expectations
      result = UserDefinedWord.where(user_id: user).first
      expect(result).to be_nil

      expect(page).to have_no_selector('.test-target-word', text: new_target)

      # Execution
      visit(vocab_tools_words_path(program, section, unit_id: unit.id))
      find(".test-lesson-#{lesson.id}-add-word").click
      find(".test-lesson-#{lesson.id}-new-definition").set(new_definition)
      find('.test-user-word-add-save', visible: :visible).click

      # Expectations
      result = UserDefinedWord.where(user_id: user).first
      expect(result).to be_nil

      expect(page).to have_no_selector('.test-definition-word', text: new_definition)
    end

    scenario 'As a User I can update a custom vocab word' do
      unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first
      lesson = unit.lessons.first
      create(:default_vocabulary_word, program: program, lesson: lesson)
      old_target = 'some word'
      # translation is set as target value when hide translation is true
      old_translation = old_target
      old_definition = 'some definition'
      new_target = 'new word'
      new_translation = new_target
      new_definition = 'new definition'

      word_to_update = create(
        :user_defined_word,
        lesson: lesson,
        program: program,
        target: old_target,
        translation: old_translation,
        definition: old_definition,
        user: user
      )

      visit(vocab_tools_words_path(program, section, unit_id: unit.id))
      find('.test-user-word-edit .test-music-icon-edit', visible: :visible).click
      find(".test-edit-#{word_to_update.id}-L2").set(new_target)
      find(".test-edit-#{word_to_update.id}-definition").set(new_definition)
      find('.test-user-word-edit-save', visible: :visible).click

      # Expectations
      expect(page).to have_selector('.test-target-word', text: new_target)
      expect(page).to have_no_selector('.test-translation-word', text: new_translation)
      expect(page).to have_selector('.test-definition-word', text: new_definition)
      word_to_update.reload
      expect(word_to_update.target).to eq(new_target)
      expect(word_to_update.translation).to eq(new_translation)
      expect(word_to_update.definition).to eq(new_definition)
    end

    scenario 'As a User I can delete a custom vocab word' do
      unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first
      lesson = unit.lessons.first
      create(:default_vocabulary_word, program: program, lesson: lesson)
      target = 'some word'
      translation = target
      definition = 'some definition'

      word_to_delete = create(
        :user_defined_word,
        lesson: lesson,
        program: program,
        target: target,
        translation: translation,
        definition: definition,
        user: user
      )

      visit(vocab_tools_words_path(program, section, unit_id: unit.id))
      find('.test-user-word-edit .test-music-icon-edit', visible: :visible).click
      find('.test-user-word-delete', visible: :visible).click
      find('.test-confirm-yes', visible: :visible).click

      # Expectations
      expect(page).to have_no_selector('.test-target-word', text: target)
      expect(page).to have_no_selector('.test-translation-word', text: translation)
      expect(page).to have_no_selector('.test-definition-word', text: definition)
      expect(UserDefinedWord.where(id: word_to_delete.id)).to be_empty
    end
  end

  scenario 'As a User enrolled in a course, I see the default unit range ' \
           'for the course when I visit the vocab-tools units page' do
    # Data setup: enroll in a course with a limited unit range.
    units = create_units(program, count: 4, unit_factory: :unit_with_lesson)
    # a lesson must have words to be visible in the words page.
    units.each do |unit|
      create(:default_vocabulary_word, topic: 'foo', lesson: unit.lessons.last)
    end
    units_in_range = [units[1], units[2]]
    units_out_of_range = [units[0], units[3]]
    course.update!(first_unit_id: units[1].id, last_unit_id: units[2].id)
    student = create(:student)
    enrollment = create(:active_enrollment, section: section, user: student)
    initialize_client_calls_for_user(student)
    log_in_as(student)

    visit(vocab_tools_units_path(program, section))

    expect(page).to have_link(
      'Return to Dashboard',
      href: course_section_path(course_id: course.id, section_id: section.id)
    )

    # The units in range should be visible.
    units_in_range.each do |unit|
      expect(page).to have_selector(
        words_link_selector_template % { program_id: program.id, section_id: section.id, unit_id: unit.id },
        visible: :visible
      )
    end

    # The units out of range should not be visible.
    units_out_of_range.each do |unit|
      expect(page).to have_selector(
        words_link_selector_template % { program_id: program.id, section_id: section.id, unit_id: unit.id },
        visible: :hidden
      )
    end

    # The button to view all lessons should be visible.
    expect(page).to have_button(view_all_lessons_text, visible: true)

    # The button to view just the unit range for this course should not be visible.
    expect(page).not_to have_button(view_unit_range_text, visible: true)

    # click on the button to view all lessons.
    click_button(view_all_lessons_text, visible: true)

    # All the units for the program should be visible.
    units.each do |unit|
      expect(page).to have_selector(
        words_link_selector_template % { program_id: program.id, section_id: section.id, unit_id: unit.id },
        visible: true
      )
    end

    # The button to view all lessons should not be visible.
    expect(page).not_to have_button(view_all_lessons_text, visible: true)

    # The button to view just the unit range for this course should be visible.
    expect(page).to have_button(view_unit_range_text, visible: true)

    # click on the button to view just the unit range for the course.
    click_button(view_unit_range_text, visible: true)

    # The units in range should be visible.
    units_in_range.each do |unit|
      expect(page).to have_selector(
        words_link_selector_template % { program_id: program.id, section_id: section.id, unit_id: unit.id },
        visible: true
      )
    end

    # The units out of range should not be visible.
    units_out_of_range.each do |unit|
      expect(page).to have_selector(
        words_link_selector_template % { program_id: program.id, section_id: section.id, unit_id: unit.id },
        visible: :hidden
      )
    end

    # The button to view all lessons should be visible.
    expect(page).to have_button(view_all_lessons_text, visible: true)

    # The button to view just the unit range for this course should not be visible.
    expect(page).not_to have_button(view_unit_range_text, visible: true)

    # click on one of the units and navigate to the words page.
    click_link(units[1].name)

    expect(page).to have_link(
      'Return to Dashboard',
      href: course_section_path(course_id: course.id, section_id: section.id)
    )

    # Only lessons in the unit range for the course are visible.
    #    (note that the lessons must have words to be visible.)
    units_in_range.each do |unit|
      expect(page).to have_content(unit.name)
    end
    units_out_of_range.each do |unit|
      expect(page).not_to have_content(unit.name)
    end

    # The view-all-lessons button is visible.
    expect(page).to have_button(view_all_lessons_text, visible: true)

    # The view-unit-range button is hidden.
    expect(page).not_to have_button(view_unit_range_text, visible: true)

    # click on the view-all-lessons button.
    click_button(view_all_lessons_text)
    #
    # All lessons in the program are visible.
    units.each do |unit|
      expect(page).to have_content(unit.name)
    end

    # The view-all-lessons button is hidden.
    expect(page).not_to have_button(view_all_lessons_text, visible: true)

    # The view-unit-range button is visible.
    expect(page).to have_button(view_unit_range_text, visible: true)

    # click on the view-unit-range button.
    click_button(view_unit_range_text)

    # Only lessons in the course are visible.
    units_in_range.each do |unit|
      expect(page).to have_content(unit.name)
    end
    units_out_of_range.each do |unit|
      expect(page).not_to have_content(unit.name)
    end

    # The view-all-lessons button is visible.
    expect(page).to have_button(view_all_lessons_text, visible: true)

    # The view-unit-range button is hidden.
    expect(page).not_to have_button(view_unit_range_text, visible: true)
  end

  scenario 'As a User enrolled in a course who opts to see all lessons on the ' \
           'unit page, I still see all lessons when I go to the words page',
           test_debt: true do
    pending 'This test exposes a bug in the user interface that continue to ' \
            'show the words of an hidden unit'

    program = create_program(id: 79)
    units = create_units(program, count: 4, unit_factory: :unit_with_lessons)
    # Add words to last lesson in each unit (as in current unit books)
    # so that lessons will be visible on words page.
    units.each do |unit|
      create(:default_vocabulary_word, topic: 'foo', lesson: unit.lessons.last)
    end

    course = create(:course,
                    first_unit_id: units[1].id,
                    last_unit_id: units[2].id,
                    program: program
                   )
    section = create(:section, course: course)
    student = create(:student)
    enrollment = create(:active_enrollment, section: section, user: student)

    # This is a lesson not in the course.
    last_lesson_in_first_unit = units[0].lessons.last

    initialize_client_calls_for_user(student)
    log_in_as(student)

    # Visit the units page
    visit(vocab_tools_units_path(program, section))

    # Click on view-all-lessons link
    click_link(view_all_lessons_text)
    sleep 1 # need a sleep here or the localStorage doesn't get written

    # Click on one of the not-in-course lessons.
    click_link(units[0].name)
    sleep 1

    # The lessons for the clicked unit are selected.
    expect(find(".test-lesson-#{last_lesson_in_first_unit.id}-name")).to be_checked

    # Select all units to see their lessons
    # units[1..3].each { |unit| find(".test-unit-#{unit.id}-name").click }

    # All lessons are visible on the words page.
    # units.each do |unit|
    #   expect(page).to have_content(unit.lessons.last.name)
    # end

    # The view-all-lessons button is hidden.
    expect(page).to have_selector('button', text: view_all_lessons_text, visible: :hidden)

    # The view-unit-range button is visible.
    expect(page).to have_selector('button', text: view_unit_range_text, visible: true)

    # click the view-unit-range button.
    click_button(view_unit_range_text)

    # The lessons for the clicked unit are not selected.
    expect(find(".test-lesson-#{last_lesson_in_first_unit.id}-name")).not_to be_checked
  end

  scenario 'As a User not enrolled in a course, I see the full unit range ' \
           'for the program when I visit the vocab-tools units page' do
    program = create_program(id: 79)
    units = create_units(program, count: 4, unit_factory: :unit_with_lessons)
    # Set this up to be like current unit books for now, where all words are in second lesson.
    units.each { |unit| create(:default_vocabulary_word, topic: 'foo', lesson: unit.lessons.last) }

    student = create(:student)
    initialize_client_calls_for_user(student)
    log_in_as(student)

    visit(vocab_tools_units_path(program, section_zero))

    # All the units in the program are visible.
    units.each do |unit|
      expect(page).to have_selector(
        words_link_selector_template % { program_id: program.id, section_id: 0, unit_id: unit.id },
        visible: :visible
      )
    end

    # the button to view all lessons should not be visible
    expect(page).not_to have_button(view_all_lessons_text, visible: true)
    #
    # the button to view just the unit range for this course should not be visible
    expect(page).not_to have_button(view_unit_range_text, visible: true)

    # click on any unit.
    click_link(units[1].name)

    # All lessons are visible.
    # Note: this page take sometimes a long time to load, so we increase the
    # capybara default timeout here.
    Capybara.using_wait_time 20 do
      units.each do |unit|
        expect(page).to have_selector(".test-lesson-#{unit.lessons.last.id}-name")
      end
    end

    # the button to view all lessons should not be visible
    expect(page).not_to have_button(view_all_lessons_text, visible: true)

    # the button to view just the unit range for this course should not be visible
    expect(page).not_to have_button(view_unit_range_text, visible: true)
  end

  def lesson_disclosure_selector(lesson)
    ".js-topic-list-disclosure-#{lesson.id}"
  end

  def expect_lesson(lesson, visible:, topics_selected:)
    if visible
      # check if the lesson disclosure body visibility
      wait_for_ajax
      expect(page).to have_selector(".test-disclosure-body-lesson-#{lesson.id}", visible: true)
      # check all topics
      lesson.default_vocabulary_words.each_with_index do |word, index|
        expect(page).to have_selector('.test-topic-name', text: word.topic, visible: true)
        expect(find("#topic-#{lesson.id}-#{index}-checkbox", visible: true).checked?)
          .to eq(topics_selected[index])
      end
    else
      # check if the lesson disclosure body visibility
      wait_for_ajax
      expect(page).to have_selector(".test-disclosure-body-lesson-#{lesson.id}", visible: :hidden)
      # since topics are loaded dynamically, they can either not exist or be hidden
      lesson.default_vocabulary_words.each_with_index do |word, index|
        expect(first('.test-topic-name', text: word.topic, visible: true)).to be_nil
      end
    end
    # the "select all" checkbox is selected if all the topics are selected
    if topics_selected.uniq.length == 1 && topics_selected[0]
      expect(find(".test-lesson-#{lesson.id}-name", visible: :all)).to be_checked
    else
      expect(find(".test-lesson-#{lesson.id}-name", visible: :all)).not_to be_checked
    end
  end

  def disclose_unit(unit)
    find(".js-unit-#{unit.id}-disclosure-button").click
    # after disclosing we wait for the disclosure body to be visible
    loop do
      break if page.has_selector?("#disclosure-body-#{unit.id}", visible: true)
    end
  end

  def disclose_lesson(lesson)
    find(".js-topic-list-disclosure-#{lesson.id}", visible: true).click
    # disclosing a lesson causes an ajax request, so we wait for completion before returning
    WaitForAjax
  end

  def click_on_lesson_select_all(lesson)
    find(".js-lesson-#{lesson.id}-select-all", visible: true).click
  end

  def click_on_lesson_topic(lesson, topic_index)
    find(".test-topic-#{lesson.id}-#{topic_index}").click
  end

  scenario 'As a User, I can choose vocabulary from multiple lessons in ' \
           'the words page', test_debt: true, retry: 2 do
    pending 'Intermittent failures seen in this scenario'
    raise # TODO: Remove this raise when trying to fix the intermitten failure.
    units = create_units(program, count: 2, unit_factory: :unit_with_lessons)

    units.each do |unit|
      unit.lessons.each do |lesson|
        (1..3).each do |i|
          word = create(:default_vocabulary_word,
                        program: program,
                        lesson: lesson,
                        topic: "unit-#{unit.id}-lesson-#{lesson.id}-topic-#{i}"
                       )
        end
      end
    end

    student = create(:student)
    initialize_client_calls_for_user(student)
    log_in_as(student)

    # visit the words page, but don't specify a unit.
    visit(vocab_tools_words_path(program, section))
    wait_for_ajax

    purpose 'By default, none of the lessons is visible nor selected' do
      expect_lesson(units[0].lessons[0], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[0].lessons[1], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[0], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[1], visible: false, topics_selected: [false, false, false])
    end

    purpose 'By default, there are no topics assigned to any of the lessons' do
      expect(page).not_to have_selector('.test-topic-name')
    end

    purpose 'Disclosing a unit makes it visible' do
      units[0].lessons.each do |lesson|
        expect(page).to have_no_selector(lesson_disclosure_selector(lesson), visible: true)
      end

      disclose_unit(units.first)

      units[0].lessons.each do |lesson|
        expect(page).to have_selector(lesson_disclosure_selector(lesson), visible: true)
      end
    end

    purpose 'Disclosing a lesson makes it visible' do
      disclose_lesson(units[0].lessons[0])

      expect_lesson(units[0].lessons[0], visible: true, topics_selected: [false, false, false])
      expect_lesson(units[0].lessons[1], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[0], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[1], visible: false, topics_selected: [false, false, false])
    end

    purpose 'Clicking on "select all" selects all the lesson topics' do
      click_on_lesson_select_all(units[0].lessons[0])

      expect_lesson(units[0].lessons[0], visible: true, topics_selected: [true, true, true])
      expect_lesson(units[0].lessons[1], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[0], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[1], visible: false, topics_selected: [false, false, false])
    end

    purpose 'Unselecting one topic automatically unchecks the "select all" checkbox' do
      click_on_lesson_topic(units[0].lessons[0], 1)

      expect_lesson(units[0].lessons[0], visible: true, topics_selected: [true, false, true])
      expect_lesson(units[0].lessons[1], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[0], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[1], visible: false, topics_selected: [false, false, false])
    end

    purpose 'Unchecking "select all" unselects all the lesson topics' do
      disclose_lesson(units[0].lessons[1])
      click_on_lesson_select_all(units[0].lessons[1])

      expect_lesson(units[0].lessons[0], visible: true, topics_selected: [true, false, true])
      expect_lesson(units[0].lessons[1], visible: true, topics_selected: [true, true, true])
      expect_lesson(units[1].lessons[0], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[1], visible: false, topics_selected: [false, false, false])

      click_on_lesson_select_all(units[0].lessons[1])

      expect_lesson(units[0].lessons[0], visible: true, topics_selected: [true, false, true])
      expect_lesson(units[0].lessons[1], visible: true, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[0], visible: false, topics_selected: [false, false, false])
      expect_lesson(units[1].lessons[1], visible: false, topics_selected: [false, false, false])
    end
  end

  scenario 'As a user, I can not see translation related options in Study Modes ' \
           'if hide translation is true ' do
    allow(Maestro::ApiToken).to receive(:fetch).and_return(api_token)
    allow(ProgramSettings).to receive(:new).and_return(program_setting)
    allow(program_setting).to receive(:hide_translation?).and_return(true)
    allow(program_setting).to receive(:has_vocab_definition?).and_return(true)
    unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first
    lesson = unit.lessons.first
    create(
      :default_vocabulary_word,
      audio_paths: ['foo.mp3'],
      lesson: lesson,
      program: program,
      target: 'capitulado/a hi'
    )
    visit(vocab_tools_words_path(program, section, unit_id: unit.id))
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
    allow(ProgramSettings).to receive(:new).and_return(program_setting)
    allow(program_setting).to receive(:hide_translation?).and_return(false)
    allow(program_setting).to receive(:has_vocab_definition?).and_return(true)
    unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first
    lesson = unit.lessons.first
    create(
      :default_vocabulary_word,
      audio_paths: ['foo.mp3'],
      lesson: lesson,
      program: program,
      target: 'capitulado/a hi'
    )
    visit(vocab_tools_words_path(program, section, unit_id: unit.id))
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
    unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first
    lesson = unit.lessons.first
    vocab_word = create(:default_vocabulary_word,
                        audio_paths: ['foo.mp3'],
                        lesson: lesson,
                        program: program,
                        target: 'capitulado/a hi'
                       )

    visit(vocab_tools_words_path(program, section, unit_id: unit.id))
    find('.test-flashcards-link').click
    # Select target->English mode
    select 'to English', from: 'study_mode_select'
    find('.test-start-activity').click

    # The audio controls should be present.
    expect(page).to have_selector('.test-flashcard-audio-controls')

    visit(vocab_tools_words_path(program, section, unit_id: unit.id))
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
    visit(vocab_tools_words_path(program, section, unit_id: unit.id))
    find('.test-flashcards-link').click
    find('.test-start-activity').click
    # The audio controls should not be present.
    expect(page).not_to have_selector('.test-flashcard-audio-controls')
  end

  def expect_redirect_to_login_page
    url = page.current_url
    expect(url.start_with?(UA_URL) && url.include?('/login')).to be_truthy
  end

  scenario 'As a user who is not logged in, if I visit the units or words ' \
           'page, I am redirected to the login page',
           :skip_login, clear_local_storage: false do

    skip "SEE: https://vistahl.atlassian.net/browse/MAE-54225"

    # visit the units page
    visit(vocab_tools_units_path(program, section))
    expect_redirect_to_login_page

    # visit the words page.
    visit(vocab_tools_words_path(program, section))
    expect_redirect_to_login_page
  end

  def expect_redirect_to_home_page
    url = page.current_url
    expect(url).to start_with(UA_URL)
    expect(url).to include('/home')
  end

  scenario 'As a user without the right license, I am not allowed access to ' \
           'the vocab tools and I am redirected to the home page',
           :no_user_licence, clear_local_storage: false do

    skip "SEE: https://vistahl.atlassian.net/browse/MAE-54225"

    # visit the units page.
    visit(vocab_tools_units_path(program, section))
    expect_redirect_to_home_page

    # visit the words page.
    visit(vocab_tools_words_path(program, section))
    expect_redirect_to_home_page
  end

  scenario 'As a user, when I click on a unit in the units page for a units ' \
           'book, I see the unit lessons checked' do
    unit = create_units(program, count: 1, unit_factory: :unit_with_lesson).first

    unit.lessons.each do |lesson|
      create(:default_vocabulary_word, program: program, lesson: lesson)
    end
    student = create(:student)
    initialize_client_calls_for_user(student)
    log_in_as(student)

    # visit the units page.
    visit(vocab_tools_units_path(program, section))

    # click on any unit.
    click_link(unit.name)
    wait_for_ajax

    # The lessons associated with the unit should be checked.
    unit.lessons.each do |lesson|
      expect(find(".test-lesson-#{lesson.id}-name")).to be_checked
    end
  end
end
