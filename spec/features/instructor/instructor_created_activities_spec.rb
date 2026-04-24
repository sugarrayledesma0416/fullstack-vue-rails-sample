feature 'Instructor-created Activities', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include Capybara::Angular::DSL
  include WaitForNextPage

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let!(:activity) do
    create_activity_with_unit_lesson_concept_strand_and_substrand(
      program, instructor_revision_id: 70
    )
  end
  let(:course) { create(:course, owner: instructor, program: program) }
  let!(:section) { create(:section, course: course, instructor: instructor) }
  let(:course_licenses) { [] }
  let!(:course_library_activity) do
    CourseLibraryActivity.create(
      activity_id: activity.id,
      course_id: course.id
    )
  end

  before do
    give_instructor_access_to_toc
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
    page.execute_script('sessionStorage.clear();')
  end

  def visit_my_content_form
    add_content = find('.create-activity-links')
    within(add_content) do
      add_content.click
      wait_for_selector('.new-content')
      new_content = find('.new-content')
      new_content.click
      wait_for_selector('.my-content')
      new_content.find('.my-content').click
    end
  end

  def visit_new_activity_form(name)
    add_content = find('.create-activity-links')
    within(add_content) do
      add_content.click
      wait_for_selector('.new-activity')
      new_activity = find('.new-activity')
      new_activity.click
      wait_for_selector('.create-activity-link')
      new_activity.find('.create-activity-link', text: name, exact_text: true).click
    end
  end

  def fill_in_activity_title(title)
    within('.test-activity-title') do
      wait_for_selector('.test-edit-icon')
      find('.test-edit-icon', visible: true).click
      find('input').set(title)
    end
  end

  def fill_in_activity_direction_line(text)
    within('.test-activity-direction-line') do
      wait_for_selector('.test-edit-icon')
      find('.test-edit-icon', visible: true).click
      fill_in_froala(text)
    end
  end

  def fill_in_question_prompt(text)
    within('.test-question-prompt') do
      wait_for_selector('.test-edit-icon')
      find('.test-edit-icon', visible: true).click
      find('input').set(text)
    end
  end

  def fill_in_question_choice(elm, text)
    within(elm) do
      wait_for_selector('.test-edit-icon')
      find('.test-edit-icon', visible: true).click
      find('input').set(text)
    end
  end

  def activity_add_reference(type, text)
    find('.test-add-reference').click
    find(".test-reference-menu-#{type}", text: text).click
  end

  def activity_add_wordbank_reference(text)
    activity_add_reference('wordbank', 'Wordbank')
    within('.test-wordbank-reference-wrapper') do
      find('.test-wordbank-edit-link', visible: true).click
      find('.test-wordbank-input').set(text)
    end
  end

  def activity_delete_wordbank_reference
    within('.test-wordbank-reference-wrapper') do
      find('.test-reference-delete-link', visible: true).click
      find('.test-confirm-delete', visible: true).click
    end
  end

  def add_text_reference_header(text)
    within('.test-header_wrapper') do
      find('.test-edit-icon', visible: true).click
      find('input').set(text)
    end
  end

  def add_text_reference_body(text)
    within('.test-body_wrapper') do
      find('.test-edit-icon', visible: true).click
      find('input').set(text)
    end
  end

  def activity_add_text_reference(header, body)
    activity_add_reference('text', 'Text')
    within('.test-text-reference-wrapper') do
      add_text_reference_header(header)
      add_text_reference_body(body)
    end
  end

  def activity_delete_text_reference
    within('.test-text-reference-wrapper') do
      find('.test-reference-delete-link', visible: true).click
      find('.test-confirm-delete', visible: true).click
    end
  end

  def activity_add_youtube_video_link(video_id)
    find('.test-url-edit-link',
         text: 'Add Youtube or Vimeo link (required)').click
    modal = find('.test-video-url-dialog')
    within(modal) do
      find('.test-url-textarea').set(
        "https://www.youtube.com/embed/#{video_id}"
      )
      wait_for_selector('.test-save-url')
      find('.test-save-url').click
    end
  end

  def activity_add_external_link(link_url)
    find('.test-add-external-link-btn',
         text: 'Add External link (required)').click
    save_external_link(link_url)
  end

  def activity_edit_external_link(link_url)
    find('.test-external-link-edit-btn').click
    save_external_link(link_url)
  end

  def save_external_link(link_url)
    modal = find('.test-external-link-editor')
    within(modal) do
      find('.test-external-link-input-box').set(link_url)
      find('.test-save-url').click
    end
  end

  def add_question
    find('.test-add-question-link').click
  end

  def delete_question
    within(all('.test-assessment-question-wrapper').last) do
      find('.test-button-delete').click
    end
  end

  def set_check_box_value(selector, value)
    elm = page.find(selector)
    if value
      page.check(elm['id'], allow_label_click: true)
    else
      page.uncheck(elm['id'], allow_label_click: true)
    end
  end

  def visit_edit_activity_page(instructor_created_activities, activity_id)
    step 'Visit the edit activity page' do
      instructor_created_activities.find(
        ".test-icon-edit#edit_activity_link_#{activity_id}"
      ).click
    end
  end

  def validate_title(title)
    step 'I can see the activity title' do
      expect(page).to have_selector('.test-activity-title .test-editable-attr-value', text: title)
    end
  end

  def validate_direction_line(direction_line)
    step 'I can see the activity direction line' do
      expect(page).to have_selector(
        '.test-activity-direction-line .test-editable-attr-value', text: direction_line
      )
    end
  end

  def validate_question_prompt(text)
    step "I can see a question with text #{text}" do
      expect(page).to have_selector(
        '.test-question-prompt', text: text
      )
    end
  end

  def validate_adding_question
    step 'Click on "Add another question"' do
      add_question
    end

    step 'I can see two question prompts' do
      expect(all('.test-question-prompt').length).to eq(2)
    end
  end

  def validate_delete_question
    step 'Click on delete question icon' do
      delete_question
    end

    step 'I can see a message dialog with text "Delete this question?"' do
      expect(page).to have_selector('.test-message-box-content', text: 'Delete this question?')
    end

    step 'Confirm the deletion' do
      find('.test-message-box .test-message-box-delete').click
    end

    step 'I can see only one question prompt' do
      expect(all('.test-question-prompt').length).to eq(1)
    end
  end

  def add_blank(text)
    step 'Click on "Add blank"' do
      find('.test-add-blank-button').click
    end

    step 'Click on "Add answers"' do
      find('.test-label-draggable-blank').click
    end

    step 'Fill in the answer' do
      find('.test-fib-answer').set(text)
    end

    step 'Click on "Save" answer' do
      find('.test-save-edits').click
    end
  end

  def add_text(text)
    step 'Click on "Add text"' do
      find('.test-add-text-button').click
    end

    step 'Fill in the text' do
      find('.test-prompt-text-elm').send_keys(text)
    end
  end

  def add_drop_down_menu_option(number, text, is_correct)
    step 'Click on "Add Option"' do
      find('.test-add-option').click
    end

    step 'Fill in Option' do
      find(".test-drop-down-option-#{number}").set(text)
    end

    return unless is_correct

    step 'Set correct option' do
      find(".test-mark-correct-option-#{number}").click
    end
  end

  scenario 'Instructor creates a new composition activity' do
    lesson = activity.lesson
    lesson.strands.each do |strand|
      next if Concept.where(id: strand.location).exists?

      create_concept_matching_strand_id(strand, name: strand.title, lesson: lesson)
    end
    wait_for_next_page do
      visit instructor_toc_path(program)
    end

    title = 'Fake activity title'
    direction_line = 'Errores opticos del tiempo y de la luz.'
    question_prompt = 'Subdivisions? in the high school halls? in the shopping malls?'
    wordbank_items = %w[cat dog soap spoon]
    text_reference_header = 'Fake text reference header'
    text_reference_body = 'Fake text reference body'
    new_question_prompt = 'New question Prompt'
    new_wordbank_items = %w[apple mango orange]
    new_text_reference_header = 'New text reference header'
    new_text_reference_body = 'New text reference body'

    new_title = 'New fake activity title'
    new_direction_line = 'New Errores opticos del tiempo y de la luz.'

    # There is no instructor-created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).to be_nil

    # Create a new activity
    wait_for_next_page do
      visit_new_activity_form('Composition')
    end
    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)
    fill_in_question_prompt(question_prompt)
    activity_add_wordbank_reference(wordbank_items.join(', '))
    activity_add_text_reference(text_reference_header, text_reference_body)

    # save the activity and make sure it gets created
    wait_for_next_page do
      find('.test-save-share-activity').click
    end

    # Activity should have been saved correctly
    new_activity = InstructorCreatedActivity.last
    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to include title
    expect(new_activity.direction_line).to include direction_line
    expect(new_activity.content_object.items.first.body.content).to eq(
      wordbank_items.join("\n")
    )
    expect(new_activity.content_object.items.third.prompt.content) \
      .to eq(question_prompt)

    # Check saved references
    saved_references = new_activity.references.list
    expect(saved_references.size).to be 2
    expect(saved_references.first).to have_attributes(
      type: 'wordbank',
      header: nil,
      body: wordbank_items.join(',')
    )
    expect(saved_references.second).to have_attributes(
      type: 'text',
      header: text_reference_header,
      body: text_reference_body
    )
    expect(new_activity.minutes_to_complete).not_to be_nil

    expect(InstructorActivityRevision.last.id).to eq(new_activity.instructor_revision_id)

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    # Activity should appears in the Instructor-created Activities
    expect(instructor_created_activities).to have_selector(
      ".instructor.activity_link#activity_#{new_activity.id}",
      text: title
    )

    # Edit the activity
    wait_for_next_page do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)
    end

    validate_title(title)
    validate_direction_line(direction_line)

    # The body should not have the ns-composition class
    element = find('body')
    expect(element[:class]).not_to include('ns-composition')

    # Edit the title
    fill_in_activity_title(new_title)

    # Edit direction line
    fill_in_activity_direction_line(new_direction_line)

    # Question prompt should be set
    element = find('.test-question-prompt .test-editable-attr-value')
    expect(element.text).to eq(question_prompt)

    # Edit Question prompt
    fill_in_question_prompt(new_question_prompt)

    # Delete wordbank reference
    activity_delete_wordbank_reference
    expect(page).not_to have_selector('.test-wordbank-reference-wrapper')

    # Add new wordbank reference
    activity_add_wordbank_reference(new_wordbank_items.join(', '))

    # Delete text reference
    activity_delete_text_reference
    expect(page).not_to have_selector('.test-text-reference-wrapper')

    # Add new text reference
    activity_add_text_reference(
      new_text_reference_header,
      new_text_reference_body
    )

    # save the modifications
    wait_for_next_page do
      find('.test-save-share-activity').click
    end

    updated_activity = InstructorCreatedActivity.last
    @recycle_bin << updated_activity.content_filepath
    expect(updated_activity.title).to include new_title
    expect(updated_activity.direction_line).to include new_direction_line
    expect(updated_activity.content_object.items.third.prompt.content) \
      .to eq(new_question_prompt)

    updated_references = updated_activity.references.list
    expect(updated_references.size).to be 2
    expect(updated_references.first).to have_attributes(
      type: 'wordbank',
      header: nil,
      body: new_wordbank_items.join(',')
    )
    expect(updated_references.second).to have_attributes(
      type: 'text',
      header: new_text_reference_header,
      body: new_text_reference_body
    )
  end

  scenario 'Instructor creates a new embebbed video activity' do
    title = 'Verbs'
    direction_line = 'Foo Baz Bar'
    youtube_video_id = 'Y-G4PTysacI'

    allow(MaestroActivityEngine::ActivityContent::ExternalVideoContent) \
      .to receive(:parse_video_id).and_return(youtube_video_id)

    wait_for_next_page do
      visit instructor_toc_path(program)
    end

    visit_new_activity_form('Video')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)
    activity_add_youtube_video_link(youtube_video_id)

    wait_for_selector('.test-save-share-activity')
    # save the activity and make sure it gets created
    find('.test-save-share-activity').click

    new_activity = InstructorCreatedActivity.last

    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to eq(title)
    expect(new_activity.direction_line).to include(direction_line)
    expect(new_activity.content_object.video_id).to eq(youtube_video_id)
    expect(InstructorActivityRevision.last.id).to eq(new_activity.instructor_revision_id)

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    step 'I can see the activity in the Instructor-created activities list' do
      expect(instructor_created_activities).to have_selector(
        ".instructor.activity_link#activity_#{new_activity.id}",
        text: title
      )
    end

    purpose 'I visit the edit activity page and check if information is displayed correctly' do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)

      validate_title(title)
      validate_direction_line(direction_line)
    end
  end

  scenario 'Instructor creates a new Partner Chat Activity' do
    title = 'Partner Chat Activity'
    direction_line = 'Test Direction Line'

    visit instructor_toc_path(program)
    visit_new_activity_form('Partner Chat')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)

    step 'I can see a text "This will appear to the left of your reference(s)"' do
      expect(page).to have_selector(
        '.test-activity-image-header-text',
        text: 'This will appear to the left of your reference(s)'
      )
    end

    step 'I can save the activity' do
      wait_for_next_page do
        find('.test-save-share-activity').click
      end
    end

    # Activity should have been saved correctly
    new_activity = InstructorCreatedActivity.last
    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to include title
    expect(new_activity.direction_line).to include direction_line

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    step 'I can see the activity in the Instructor-created activities list' do
      expect(instructor_created_activities).to have_selector(
        ".instructor.activity_link#activity_#{new_activity.id}",
        text: title
      )
    end

    purpose 'I visit the edit activity page and check if information is displayed correctly' do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)

      validate_title(title)
      validate_direction_line(direction_line)

      step 'I can see a text "This will appear to the left of your reference(s)"' do
        expect(page).to have_selector(
          '.test-activity-image-header-text',
          text: 'This will appear to the left of your reference(s)'
        )
      end
    end
  end

  scenario 'Instructor creates a new Multiple Choice Activity' do
    title = 'Multiple Choice Activity'
    direction_line = 'Test Direction Line'

    visit instructor_toc_path(program)
    visit_new_activity_form('Multiple Choice (2 options)')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)

    within('.test-assessment-question-wrapper') do
      validate_question_prompt('Write your question prompt here (optional)')

      step 'I can see a 2 options' do
        expect(page).to have_selector('.test-question-choice-1', text: 'Option')
        expect(page).to have_selector('.test-question-choice-2', text: 'Option')
      end
    end

    purpose 'I can add a new question' do
      validate_adding_question
    end

    purpose 'I can delete a question' do
      validate_delete_question
    end

    purpose 'I can edit a question' do
      step 'Fill in the question prompt' do
        fill_in_question_prompt('Test Question')
      end

      step 'Fill in choices' do
        all('.test-question-choice').each_with_index do |choice, index|
          fill_in_question_choice(choice, "Choice #{index + 1}")
        end
      end
    end

    step 'I can save the activity' do
      wait_for_next_page do
        find('.test-save-share-activity').click
      end
    end

    # Activity should have been saved correctly
    new_activity = InstructorCreatedActivity.last
    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to include title
    expect(new_activity.direction_line).to include direction_line

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    step 'I can see the activity in the Instructor-created activities list' do
      expect(instructor_created_activities).to have_selector(
        ".instructor.activity_link#activity_#{new_activity.id}",
        text: title
      )
    end

    purpose 'I visit the edit activity page and check if information is displayed correctly' do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)

      validate_title(title)
      validate_direction_line(direction_line)

      validate_question_prompt('Test Question')

      step 'I can see question choices "Choice 1" and "Choice 2"' do
        expect(page).to have_selector('.test-question-choice-1', text: 'Choice 1')
        expect(page).to have_selector('.test-question-choice-2', text: 'Choice 2')
      end
    end
  end

  scenario 'Instructor creates a new True False Activity' do
    title = 'True False Activity'
    direction_line = 'Test Direction Line'

    visit instructor_toc_path(program)
    visit_new_activity_form('True or False')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)

    within('.test-assessment-question-wrapper') do
      validate_question_prompt('Write your question prompt here (optional)')

      step 'I can see a 2 options' do
        expect(page).to have_selector('.test-question-choice-1', text: 'True')
        expect(page).to have_selector('.test-question-choice-2', text: 'False')
      end
    end

    purpose 'I can add a new question' do
      validate_adding_question
    end

    purpose 'I can delete a question' do
      validate_delete_question
    end

    purpose 'I can edit a question' do
      step 'Fill in the question prompt' do
        fill_in_question_prompt('Test Question')
      end

      step 'Fill in choices' do
        all('.test-question-choice').each_with_index do |choice, index|
          fill_in_question_choice(choice, "Multiple Choice Same #{index + 1}")
        end
      end
    end

    step 'I can save the activity' do
      wait_for_next_page do
        find('.test-save-share-activity').click
      end
    end

    # Activity should have been saved correctly
    new_activity = InstructorCreatedActivity.last
    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to include title
    expect(new_activity.direction_line).to include direction_line

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    step 'I can see the activity in the Instructor-created activities list' do
      expect(instructor_created_activities).to have_selector(
        ".instructor.activity_link#activity_#{new_activity.id}",
        text: title
      )
    end

    purpose 'I visit the edit activity page and check if information is displayed correctly' do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)

      validate_title(title)
      validate_direction_line(direction_line)

      validate_question_prompt('Test Question')

      step 'I can see question choices "Multiple Choice Same 1" and "Multiple Choice Same 2"' do
        expect(page).to have_selector('.test-question-choice-1', text: 'Multiple Choice Same 1')
        expect(page).to have_selector('.test-question-choice-2', text: 'Multiple Choice Same 2')
      end
    end
  end

  scenario 'Instructor creates a new Multiple Answer Activity' do
    title = 'Multiple Answer Activity'
    direction_line = 'Test Direction Line'

    visit instructor_toc_path(program)
    visit_new_activity_form('Multiple Answer')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)

    within('.test-assessment-question-wrapper') do
      validate_question_prompt('Write your question prompt here (optional)')

      step 'I can see 3 choices' do
        expect(page).to have_selector('.test-question-choice-1', text: 'Choice text')
        expect(page).to have_selector('.test-question-choice-2', text: 'Choice text')
        expect(page).to have_selector('.test-question-choice-3', text: 'Choice text')
      end
    end

    purpose 'I can add a new question' do
      validate_adding_question
    end

    purpose 'I can delete a question' do
      validate_delete_question
    end

    purpose 'I can add a new choice' do
      step 'Click on "Add Choice"' do
        find('.test-add-choice-link').click
      end

      step 'I can see 4 question choices' do
        expect(all('.test-question-choice').length).to eq(4)
      end
    end

    purpose 'I can delete a choice' do
      step 'Click on "Delete Choice Icon"' do
        find('.test-delete-choice-3').click
      end

      step 'I can see 3 question choices' do
        expect(all('.test-question-choice').length).to eq(3)
      end
    end

    purpose 'I can edit a question' do
      step 'Fill in the question prompt' do
        fill_in_question_prompt('Test Question')
      end

      step 'Fill in choices' do
        all('.test-question-choice').each_with_index do |choice, index|
          fill_in_question_choice(choice, "Option #{index + 1}")
        end
      end

      step 'Set the choice values' do
        set_check_box_value('.test-checkbox-choice-0', false)
        set_check_box_value('.test-checkbox-choice-1', true)
        set_check_box_value('.test-checkbox-choice-2', true)
      end
    end

    step 'I can save the activity' do
      wait_for_next_page do
        find('.test-save-share-activity').click
      end
    end

    # Activity should have been saved correctly
    new_activity = InstructorCreatedActivity.last
    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to include title
    expect(new_activity.direction_line).to include direction_line

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    step 'I can see the activity in the Instructor-created activities list' do
      expect(instructor_created_activities).to have_selector(
        ".instructor.activity_link#activity_#{new_activity.id}",
        text: title
      )
    end

    purpose 'I visit the edit activity page and check if information is displayed correctly' do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)

      validate_title(title)
      validate_direction_line(direction_line)

      validate_question_prompt('Test Question')

      step 'I can see question choices "Option 1", "Option 2" and "Option 3"' do
        expect(page).to have_selector('.test-question-choice-1', text: 'Option 1')
        expect(page).to have_selector('.test-question-choice-2', text: 'Option 2')
        expect(page).to have_selector('.test-question-choice-3', text: 'Option 3')
      end

      step 'I can see the choices are correctly set' do
        expect(find('.test-checkbox-choice-0')).not_to be_checked
        expect(find('.test-checkbox-choice-1')).to be_checked
        expect(find('.test-checkbox-choice-2')).to be_checked
      end
    end
  end

  scenario 'Instructor creates a new External Link Activity' do
    title = 'External Link Activity'
    direction_line = 'Test Direction Line'
    wordbank_items = %w[cat dog soap spoon]
    text_reference_header = 'Fake text reference header'
    text_reference_body = 'Fake text reference body'
    external_link_url = 'https://external-link-1.com'
    new_wordbank_items = %w[apple mango orange]
    new_text_reference_header = 'New text reference header'
    new_text_reference_body = 'New text reference body'
    new_title = 'New External Link title'
    new_direction_line = 'New Errores opticos del tiempo y de la luz.'
    new_external_link_url = 'https://external-link-1.com'

    visit instructor_toc_path(program)
    visit_new_activity_form('External Link')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)
    activity_add_wordbank_reference(wordbank_items.join(', '))
    activity_add_text_reference(text_reference_header, text_reference_body)
    activity_add_external_link(external_link_url)

    step 'I can see the external link warning dialog' do
      expect(page).to have_selector(
        '.test-terms-of-use-warning',
        text: 'Vista Higher Learning is not responsible for the ' \
        'third party websites you provide for this activity.'
      )
    end

    step 'Click "OK" to confirm the url' do
      find('.test-confirm-terms-of-use-btn').click
    end

    step 'I can save the activity' do
      wait_for_next_page do
        find('.test-save-share-activity').click
      end
    end

    # Activity should have been saved correctly
    new_activity = InstructorCreatedActivity.last
    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to include title
    expect(new_activity.direction_line).to include direction_line
    expect(
      new_activity.content_object.external_link_url
    ).to include(external_link_url)

    # Check saved references
    saved_references = new_activity.references.list
    expect(saved_references.size).to be 2
    expect(saved_references.first).to have_attributes(
      type: 'wordbank',
      header: nil,
      body: wordbank_items.join(',')
    )
    expect(saved_references.second).to have_attributes(
      type: 'text',
      header: text_reference_header,
      body: text_reference_body
    )

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    step 'I can see the activity in the Instructor-created activities list' do
      expect(instructor_created_activities).to have_selector(
        ".instructor.activity_link#activity_#{new_activity.id}",
        text: title
      )
    end

    purpose 'I visit the edit activity page and check if information is displayed ' \
      'correctly' do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)

      validate_title(title)
      validate_direction_line(direction_line)

      fill_in_activity_title(new_title)
      fill_in_activity_direction_line(new_direction_line)

      # Delete wordbank reference
      activity_delete_wordbank_reference
      expect(page).not_to have_selector('.test-wordbank-reference-wrapper')

      # Add new wordbank reference
      activity_add_wordbank_reference(new_wordbank_items.join(', '))

      # Delete text reference
      activity_delete_text_reference
      expect(page).not_to have_selector('.test-text-reference-wrapper')

      # Add new text reference
      activity_add_text_reference(
        new_text_reference_header,
        new_text_reference_body
      )

      step 'I can see the external link' do
        expect(page).to have_selector(
          '.test-external-url-value',
          text: external_link_url
        )
      end

      # Update the external link
      activity_edit_external_link(new_external_link_url)

      step 'I can see the external link warning dialog' do
        expect(page).to have_selector(
          '.test-terms-of-use-warning',
          text: 'Vista Higher Learning is not responsible for the ' \
          'third party websites you provide for this activity.'
        )
      end

      step 'Click "OK" to confirm the url' do
        find('.test-confirm-terms-of-use-btn').click
      end

      # save the modifications
      wait_for_next_page do
        find('.test-save-share-activity').click
      end

      updated_activity = InstructorCreatedActivity.last
      @recycle_bin << updated_activity.content_filepath
      expect(updated_activity.title).to include new_title
      expect(
        updated_activity.direction_line
      ).to include new_direction_line
      expect(
        updated_activity.content_object.external_link_url
      ).to include(new_external_link_url)

      updated_references = updated_activity.references.list
      expect(updated_references.size).to be 2
      expect(updated_references.first).to have_attributes(
        type: 'wordbank',
        header: nil,
        body: new_wordbank_items.join(',')
      )
      expect(updated_references.second).to have_attributes(
        type: 'text',
        header: new_text_reference_header,
        body: new_text_reference_body
      )
    end
  end

  scenario 'Instructor creates a new Audio Recording Activity' do
    title = 'Audio Recording Activity'
    direction_line = 'Test Direction Line'

    visit instructor_toc_path(program)
    visit_new_activity_form('Audio Recording')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)

    within('.test-assessment-question-wrapper') do
      validate_question_prompt('Write your question prompt here (optional)')

      step 'I can see a button with text "Add Audio Prompt"' do
        expect(page).to have_selector('.test-add-audio-prompt-button', text: 'Add Audio Prompt')
      end
    end

    purpose 'I can add new question' do
      validate_adding_question
    end

    purpose 'I can delete a question' do
      validate_delete_question
    end

    purpose 'I can add new audio prompt' do
      step 'Click on "Add Audio Prompt"' do
        find('.test-add-audio-prompt-button').click
      end

      step 'I can see dialog with heading "Edit Audio Prompt"' do
        expect(page).to have_selector('.test-modal-heading', text: 'Edit Audio Prompt')
      end

      step 'I can see button with text "Record"' do
        expect(page).to have_selector('.test-record', text: 'Record')
      end

      step 'Click on "Record" button' do
        find('.test-record button').click
      end

      step 'I can see the recording is active state' do
        expect(page).to have_selector('.test-record button.is-active')
      end

      step 'I can cancel the recording' do
        find('.test-cancel-editing').click
      end

      step 'I can not see dialog with heading "Edit Audio Prompt"' do
        expect(page).not_to have_selector('.test-modal-heading', text: 'Edit Audio Prompt')
      end
    end
  end

  scenario 'Instructor creates a new Free Response Activity' do
    title = 'Free Response Activity'
    direction_line = 'Test Direction Line'

    visit instructor_toc_path(program)
    visit_new_activity_form('Free Response')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)

    within('.test-assessment-question-wrapper') do
      validate_question_prompt('Write your question prompt here (optional)')

      step 'I can see a text area to enter response' do
        expect(page).to have_selector('.test-open-ended-text-area')
      end
    end

    purpose 'I can add a new question' do
      validate_adding_question
    end

    purpose 'I can delete a question' do
      validate_delete_question
    end

    purpose 'I can edit a question' do
      step 'Fill in the question prompt' do
        fill_in_question_prompt('Test Question')
      end
    end

    step 'I can save the activity' do
      wait_for_next_page do
        find('.test-save-share-activity').click
      end
    end

    # Activity should have been saved correctly
    new_activity = InstructorCreatedActivity.last
    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to include title
    expect(new_activity.direction_line).to include direction_line

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    step 'I can see the activity in the Instructor-created activities list' do
      expect(instructor_created_activities).to have_selector(
        ".instructor.activity_link#activity_#{new_activity.id}",
        text: title
      )
    end

    purpose 'I visit the edit activity page and check if information is displayed correctly' do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)

      validate_title(title)
      validate_direction_line(direction_line)

      validate_question_prompt('Test Question')
    end
  end

  scenario 'Instructor creates a new Fill In The Blanks activity' do
    title = 'Fill In The Blanks activity'
    direction_line = 'Test Direction Line'

    visit instructor_toc_path(program)
    visit_new_activity_form('Fill In The Blanks')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)

    within('.test-assessment-question-wrapper') do
      validate_question_prompt('Add blank or text')

      step 'I can see a "Add blank" button' do
        expect(page).to have_selector('.test-add-blank-button', text: 'Add blank')
      end

      step 'I can see a "Add text" button' do
        expect(page).to have_selector('.test-add-text-button', text: 'Add text')
      end
    end

    purpose 'I can add a new question' do
      validate_adding_question
    end

    purpose 'I can delete a question' do
      validate_delete_question
    end

    purpose 'I can edit a question' do
      step 'Add blank' do
        add_blank('Buenos días.')
      end

      step 'Add text' do
        add_text('—Buenos días. ¿Qué tal?')
      end
    end

    step 'I can save the activity' do
      wait_for_next_page do
        find('.test-save-share-activity').click
      end
    end

    # Activity should have been saved correctly
    new_activity = InstructorCreatedActivity.last
    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to include title
    expect(new_activity.direction_line).to include direction_line

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    step 'I can see the activity in the Instructor-created activities list' do
      expect(instructor_created_activities).to have_selector(
        ".instructor.activity_link#activity_#{new_activity.id}",
        text: title
      )
    end

    purpose 'I visit the edit activity page and check if information is displayed correctly' do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)

      validate_title(title)
      validate_direction_line(direction_line)
      validate_question_prompt('Buenos días. —Buenos días. ¿Qué tal?')
    end
  end

  scenario 'Instructor creates a new Drop Down activity' do
    title = 'Drop Down activity'
    direction_line = 'Test Direction Line'

    visit instructor_toc_path(program)
    visit_new_activity_form('Drop-down')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)

    within('.test-assessment-question-wrapper') do
      validate_question_prompt('Add drop-down menu or text')

      step 'I can see a "Add drop-down menu" button' do
        expect(page).to have_selector('.test-add-blank-button', text: 'Add drop-down menu')
      end

      step 'I can see a "Add text" button' do
        expect(page).to have_selector('.test-add-text-button', text: 'Add text')
      end
    end

    purpose 'I can add a new question' do
      validate_adding_question
    end

    purpose 'I can delete a question' do
      validate_delete_question
    end

    purpose 'I can edit a question' do
      step 'Add text' do
        add_text('Correct answer is ')
      end

      step 'Click on "Add drop-down menu"' do
        find('.test-add-blank-button').click
      end

      step 'Click on "Set menu options"' do
        find('.test-label-draggable-blank').click
      end

      add_drop_down_menu_option(1, 'answer 1', false)
      add_drop_down_menu_option(2, 'answer 2', true)

      step 'Click on "Save" answer' do
        find('.test-save-edits').click
      end
    end

    step 'I can save the activity' do
      wait_for_next_page do
        find('.test-save-share-activity').click
      end
    end

    # Activity should have been saved correctly
    new_activity = InstructorCreatedActivity.last
    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to include title
    expect(new_activity.direction_line).to include direction_line

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    step 'I can see the activity in the Instructor-created activities list' do
      expect(instructor_created_activities).to have_selector(
        ".instructor.activity_link#activity_#{new_activity.id}",
        text: title
      )
    end

    purpose 'I visit the edit activity page and check if information is displayed correctly' do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)

      validate_title(title)
      validate_direction_line(direction_line)

      validate_question_prompt('Correct answer is answer 2')
    end
  end

  scenario 'Instructor creates a new Solo Video Recording Activity' do
    title = 'Solo Video Recording Activity'
    direction_line = 'Test Direction Line'
    wordbank_items = %w[cat dog soap spoon]
    text_reference_header = 'Fake text reference header'
    text_reference_body = 'Fake text reference body'
    new_wordbank_items = %w[apple mango orange]
    new_text_reference_header = 'New text reference header'
    new_text_reference_body = 'New text reference body'
    new_title = 'New Solo Video Recording title'
    new_direction_line = 'New Errores opticos del tiempo y de la luz.'

    visit instructor_toc_path(program)
    visit_new_activity_form('Video Recording')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)
    activity_add_wordbank_reference(wordbank_items.join(', '))
    activity_add_text_reference(text_reference_header, text_reference_body)

    step 'I can see a text "This will appear to the left of your reference(s)"' do
      expect(page).to have_selector(
        '.test-activity-image-header-text',
        text: 'This will appear to the left of your reference(s)'
      )
    end

    step 'I can save the activity' do
      wait_for_next_page do
        find('.test-save-share-activity').click
      end
    end

    # Activity should have been saved correctly
    new_activity = InstructorCreatedActivity.last
    @recycle_bin << new_activity.content_filepath
    expect(new_activity.title).to include title
    expect(new_activity.direction_line).to include direction_line

    # Check saved references
    saved_references = new_activity.references.list
    expect(saved_references.size).to be 2
    expect(saved_references.first).to have_attributes(
      type: 'wordbank',
      header: nil,
      body: wordbank_items.join(',')
    )
    expect(saved_references.second).to have_attributes(
      type: 'text',
      header: text_reference_header,
      body: text_reference_body
    )

    # Find all created activities
    instructor_created_activities = all('table[data-container="component_header"]')[1]
    expect(instructor_created_activities).not_to be_nil
    expect(instructor_created_activities.all('.instructor.activity_link')).not_to eq([])

    step 'I can see the activity in the Instructor-created activities list' do
      expect(instructor_created_activities).to have_selector(
        ".instructor.activity_link#activity_#{new_activity.id}",
        text: title
      )
    end

    purpose 'I visit the edit activity page and check if information is displayed correctly' do
      visit_edit_activity_page(instructor_created_activities, new_activity.id)

      validate_title(title)
      validate_direction_line(direction_line)

      fill_in_activity_title(new_title)
      fill_in_activity_direction_line(new_direction_line)

      # Delete wordbank reference
      activity_delete_wordbank_reference
      expect(page).not_to have_selector('.test-wordbank-reference-wrapper')

      # Add new wordbank reference
      activity_add_wordbank_reference(new_wordbank_items.join(', '))

      # Delete text reference
      activity_delete_text_reference
      expect(page).not_to have_selector('.test-text-reference-wrapper')

      # Add new text reference
      activity_add_text_reference(
        new_text_reference_header,
        new_text_reference_body
      )

      step 'I can see a text "This will appear to the left of your reference(s)"' do
        expect(page).to have_selector(
          '.test-activity-image-header-text',
          text: 'This will appear to the left of your reference(s)'
        )
      end

      # save the modifications
      wait_for_next_page do
        find('.test-save-share-activity').click
      end

      updated_activity = InstructorCreatedActivity.last
      @recycle_bin << updated_activity.content_filepath
      expect(updated_activity.title).to include new_title
      expect(updated_activity.direction_line).to include new_direction_line

      updated_references = updated_activity.references.list
      expect(updated_references.size).to be 2
      expect(updated_references.first).to have_attributes(
        type: 'wordbank',
        header: nil,
        body: new_wordbank_items.join(',')
      )
      expect(updated_references.second).to have_attributes(
        type: 'text',
        header: new_text_reference_header,
        body: new_text_reference_body
      )
    end
  end

  scenario 'Instructor creates a new Upload File Activity' do
    title = 'Upload File Activity'
    direction_line = 'Test Direction Line'

    visit instructor_toc_path(program)
    visit_new_activity_form('Upload File')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)

    validate_title(title)
    validate_direction_line(direction_line)

    step 'I can see link to upload file button' do
      expect(page).to have_selector(
        '.test-label-for-upload-file-btn',
        text: 'Choose File'
      )
    end
  end

  scenario 'I can create an activity with images', test_debt: true do
    skip 'AWS::S3 connection error'
    # Once able to write into a S3 bucket from the CI, one can try to use the
    # Capybara function attach_file('qqfile', temp_file_path(filename))
    visit instructor_toc_path(program)
    # Stub image width and height
    allow(MiniMagick::Image).to receive(:dimensions).and_return([100, 100])

    title = 'Image activity'
    direction_line = 'Fake direction line'
    question_prompt = 'Fake question prompt'

    visit_new_activity_form('Composition')
    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)
    fill_in_question_prompt(question_prompt)

    activity_add_reference('image', 'Image')

    filename = 'reference_image_file.jpg'
    create_filename(filename)
    # hidden fields
    find(:xpath, "//input[@name='instructor_created_activity[references][0][temp_file_path]']").set temp_file_path(filename)
    find(:xpath, "//input[@name='instructor_created_activity[references][0][original_filename]']").set filename

    # save the activity and make sure it gets created
    find('.test-save-created-activity').click

    created_activity = InstructorCreatedActivity.last
    media_item = InstructorMediaItem.last
    @recycle_bin << created_activity.content_filepath

    expect(InstructorActivityRevision.last.id).to eq(created_activity.instructor_revision_id)
    expect(created_activity.content_object.items.last.image.media_item_id).to eq(created_activity.id.to_s)
  end

  scenario 'I see audio controls when I add an audio reference' do
    title = 'Audio activity'
    direction_line = 'Check my recording'

    visit instructor_toc_path(program)
    visit_new_activity_form('Composition')

    fill_in_activity_title(title)
    fill_in_activity_direction_line(direction_line)

    # Open audio reference modal
    activity_add_reference('audio', 'Audio')
    within('.test-audio-reference-wrapper') do
      expect(page).to have_selector('.test-record-button')
      expect(page).to have_selector('.test-recording-playback-button')
    end
  end

  scenario 'Instructor can assign shared activities' do
    visit instructor_toc_path(program)
    visit_new_activity_form('Composition')

    fill_in_activity_title('shared activity')
    fill_in_activity_direction_line('shared activity direction line')

    # save and share the activity
    wait_for_next_page do
      find('.test-save-share-activity').click
    end

    shared_activity = first('.js-shared-activity td')

    within(shared_activity) do
      expect(shared_activity).to have_selector('.toc_checkbox')
    end
  end

  scenario 'Instructor cannot assign draft activities' do
    visit instructor_toc_path(program)
    visit_new_activity_form('Composition')

    fill_in_activity_title('draft activity')
    fill_in_activity_direction_line('draft activity direction line')

    # save the activity as a draft
    find('.test-save-activity-draft').click

    draft_activity = first('.js-draft-activity td')

    within(draft_activity) do
      expect(draft_activity).not_to have_selector('.toc_checkbox')
    end
  end

  scenario 'Instructor can not edit an activity when my course has expired' do
    instructor_created_activity = create_instructor_activityfor_the_same_toc_location
    course.update!(end_date: Date.yesterday, allow_past_end_date: true)
    CourseLibraryActivity.create(
      activity: instructor_created_activity,
      course: course,
      hidden: true
    )
    visit instructor_toc_path(program)
    # The activity should be in the list
    expect(page).to have_selector('a.activity_link', text: instructor_created_activity.title)

    # The 'edit' link does not exist
    expect(page).not_to have_selector(
      "a[id='edit_activity_link_#{instructor_created_activity.id}']"
    )
  end

  def create_instructor_activityfor_the_same_toc_location
    lesson = program.units.first.lessons.first
    instructor_activity = create(
      :instructor_created_activity_with_non_db_attrs,
      instructor_id: instructor.id,
      lesson: lesson,
      toc_location: activity.toc_location
    )
    @recycle_bin << instructor_activity.content_filepath
    instructor_activity
  end

  def create_filename(filename)
    File.open(temp_file_path(filename), 'w') { |file| file.write('abc') }
  end

  def temp_file_path(filename)
    File.join('/tmp', filename)
  end
end
