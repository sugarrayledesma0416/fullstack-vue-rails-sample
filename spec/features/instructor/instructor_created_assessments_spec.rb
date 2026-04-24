feature 'Instructor-created Activities', chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  include ActivityTest::Helpers

  class InstructorCreatedAssessmentPageObject
    include Capybara::DSL
    include CapybaraViewHelpers
    include RspecJsCommonHelpers

    def sections
      page.all('.assessment-section-wrapper').map.with_index(1) do |wrapper, section_number|
        SectionElement.new(self, section_number)
      end
    end

    def section(number)
      SectionElement.new(self, number)
    end

    def for_section(number)
      yield section(number)
    end

    def activity_title
      find_or_fail('.activity-title input', "#{self}.activity_title").value
    end

    def activity_title=(value)
      with_element(activity_title_wrapper) do |wrapper|
        wrapper.first('.test-edit-icon', visible: true).click
        wrapper.find('input').set(value)
      end
    end

    def activity_student_title
      find_or_fail('.activity-student-title__input', "#{self}.activity_student_title").value
    end

    def activity_student_title=(value)
      with_element(activity_student_title_wrapper) do |wrapper|
        wrapper.first('.test-edit-icon', visible: true).click
        wrapper.find('#activity_student_title').set(value)
      end
    end

    def add_section(type)
      case type
      when :free_response then click_link('Free Response')
      when :external_link then click_link('External Link')
      when :solo_video_recording then click_link('Video Recording')
      when :upload_file then click_link('Upload File')
      when :fill_in_the_blanks then click_link('Fill In The Blanks')
      else
        raise NotImplementedError
      end
      Waiter.new.wait do
        page.has_selector?('.assessment-section-wrapper.is-highlighted')
      end
    end

    def save_activity
      find('.test-activity-save-button').click
      find('.test-activity-save-and-share-button').click
    end

    def save_exit_activity
      find('.test-exit-button').click
      find('.test-activity-save-and-exit-button').click
    end

    def exit_activity
      find('.test-exit-button').click
    end

    def shuffle_sections
      assessment_controls = find_or_fail(
        '.assessment-controls-assessment',
        "#{self}.assessment-controls"
      )
      within(assessment_controls) do
        find('a.test-button_shuffle_sections').click
      end
      sleep 1
    end

    private def activity_title_wrapper
      find_or_fail('.activity-title', "#{self}.activity_title")
    end

    def activity_title_info
      find_or_fail('.activity-title__info', "#{self}.activity_title_info").text
    end

    private def activity_student_title_wrapper
      find_or_fail('.activity-student-title', "#{self}.activity_student_title")
    end

    def activity_student_title_info
      find_or_fail('.activity-student-title__info', "#{self}.activity_student_title_info").text
    end
  end

  class SectionElement
    include Capybara::DSL
    include CapybaraViewHelpers
    include RspecJsCommonHelpers

    attr_reader :page_object, :section_number

    def initialize(page_object, section_number)
      @page_object = page_object
      @section_number = section_number
    end

    def visible?
      container.visible?
    end

    def edit
      control_bar = container.find('.test-control-bar-section')
      scroll_to(control_bar)
      within control_bar do
        find('a.test-button_edit').click
      end
    end

    def delete
      control_bar = container.find('.test-control-bar-section')
      scroll_to(control_bar)
      within control_bar do
        find('a.test-button_delete').click
        Waiter.new.wait do
          page.has_selector?('.assessment-controls__message-box.is-active')
        end
        # Confirm
        control_bar.click_on('delete')
      end
    end

    def save_new_section
      click_save_new_section_button
      Waiter.new.wait do
        page.has_no_selector?('.assessment-section-wrapper.is-highlighted')
      end
    rescue Timeout::Error
      click_save_new_section_button
    end

    def save_existing_section
      click_save_existing_section_button
      Waiter.new.wait do
        page.has_no_selector?('.assessment-section-wrapper.is-highlighted')
      end
    rescue Timeout::Error
      click_save_existing_section_button
    end

    private def click_save_new_section_button
      within(container) do
        button = first('.test-new-section-save-button')
        scroll_to(button)
        button.click
      end
    end

    private def click_save_existing_section_button
      within(container) do
        button = first('.test-existing-section-save-button')
        scroll_to(button)
        button.click
      end
    end

    def section_title
      section_title_wrapper.text
    end

    def section_title=(value)
      within(section_title_wrapper) do
        find('.test-edit-icon', visible: true).click
        find('input').set(value)
      end
    end

    private def section_title_wrapper
      page_object.find_nth_or_fail(
        '.assessment-section-wrapper .test-dl_header_wrapper',
        section_number - 1,
        "#{self}.section_title"
      )
    end

    def direction_line
      direction_line_wrapper.text
    end

    def direction_line=(value)
      within(direction_line_wrapper) do
        find('.test-edit-icon', visible: true).click
        fill_in_froala(value)
      end
    end

    private def direction_line_wrapper
      page_object.find_nth_or_fail(
        '.assessment-section-wrapper .test-dl_body_wrapper',
        section_number - 1,
        "#{self}.dl"
      )
    end

    def points_per_response
      points_per_response_wrapper.text
    end

    def points_per_response=(value)
      within(points_per_response_wrapper) do
        find('.test-edit-icon', visible: true).click
        find('input').set(value)
      end
    end

    def external_link_url=(value)
      find('.test-add-external-link-btn', text: 'Add External link (required)').click
      modal = find('.test-external-link-editor')
      within(modal) do
        find('.test-external-link-input-box').set(value)
        find('.test-save-url').click
      end
    end

    private def points_per_response_wrapper
      page_object.find_nth_or_fail(
        '.assessment-section-wrapper .test-points_per_response_wrapper',
        section_number - 1,
        "#{self}.points_per_response"
      )
    end

    def move_up
      within(control_bar_wrapper) do
        page.execute_script('window.TESTMODE = true;')
        find('a.test-button-move-up').click
      end
      sleep 1
    end

    def move_down
      within(control_bar_wrapper) do
        page.execute_script('window.TESTMODE = true;')
        find('a.test-button-move-down').click
      end
      sleep 1
    end

    def questions
      container.all('.assessment-question-wrapper').map.with_index(1) do |question, question_number|
        QuestionElement.new(self, question_number)
      end
    end

    def question(number)
      QuestionElement.new(self, number)
    end

    def for_question(number)
      yield question(number)
    end

    def shuffle_questions
      scroll_to(control_bar_wrapper)
      within(control_bar_wrapper) do
        find('a.test-button_shuffle_questions').click
      end
      sleep 1
    end

    def add_question
      container.click_link('Add another question')
      sleep 1
    end

    private def control_bar_wrapper
      page_object.find_nth_or_fail(
        '.test-control-bar-section',
        section_number - 1,
        "#{self}.control_bar"
      )
    end

    def add_section_reference(type)
      find('.test-add-reference').click
      within('.test-reference-menu') do
        case type
        when 'model' then click_link('Model')
        when 'list' then click_link('List')
        when 'table' then click_link('Table')
        when 'passage' then click_link('Passage')
        else
          raise NotImplementedError
        end
      end
    end

    def section_references
      container.all('.section-references li').map.with_index(1) do |reference, reference_number|
        SectionReferenceElement.new(self, reference_number)
      end
    end

    def section_reference(number)
      SectionReferenceElement.new(self, number)
    end

    def for_section_reference(number)
      yield section_reference(number)
    end

    def container
      page_object.find_nth_or_fail('.assessment-section-wrapper', section_number - 1, self)
    end
  end

  class SectionReferenceElement
    include Capybara::DSL
    include CapybaraViewHelpers
    include RspecJsCommonHelpers

    attr_reader :reference_number, :section

    def initialize(section, reference_number)
      @section = section
      @reference_number = reference_number
    end

    def to_s
      "section(#{section.section_number}).section_reference(#{reference_number})"
    end

    def text_reference?
      section.has_selector?('.test-reference_text')
      true
    end

    def image_reference?
      section.has_selector?('.test-reference_image')
    end

    def word_bank_reference?
      section.has_selector?('.test-reference_word_bank')
    end

    def text_header
      text_header_wrapper.text
    end

    def text_header=(value)
      within(text_header_wrapper) do
        find('.test-edit-icon', visible: true).click
        find('input').set(value)
      end
    end

    private def text_header_wrapper
      element_find_or_fail(
        container,
        '.test-reference_text .test-header_wrapper',
        "#{self}.text_header"
      )
    end

    def text_body
      text_body_wrapper.text
    end

    def text_body=(value)
      within(text_body_wrapper) do
        find('.test-edit-icon', visible: true).click
        find('input').set(value)
      end
    end

    private def text_body_wrapper
      element_find_or_fail(
        container,
        '.test-reference_text .test-body_wrapper',
        "#{self}.text_body"
      )
    end

    def table_caption=(value)
      within('.test-reference-table .test-table-caption-wrapper') do
        find('.test-edit-icon', visible: true).click
        fill_in_froala(value)
      end
    end

    def table_body
      find('.test-reference-table .test-table-body-wrapper').text
    end
  
    def table_body=(value)
      within('.test-reference-table .test-table-body-wrapper') do
        find('.test-edit-icon', visible: true).click
        fill_in_froala(value)
      end
    end

    private def container
      element_find_nth_or_fail(
        section.container,
        '.section-references li',
        reference_number - 1,
        self
      )
    end

    def list_header
      find(list_header_wrapper).text
    end

    def list_header=(value)
      find(list_header_wrapper).click

      within(list_header_wrapper) do
        find('.test-edit-icon', visible: true).click
        find('input').set(value)
      end
    end

    def list_body
      find(list_body_wrapper).text
    end

    def list_body=(value)
      within(list_body_wrapper) do
        find('.test-edit-icon', visible: true).click
        fill_in_froala(value)
      end
    end

    def list_header_wrapper
      '.test-reference-list .test-list-header-wrapper'
    end

    def list_body_wrapper
      '.test-reference-list .test-list-body-wrapper'
    end

    def model_header
      find(model_header_wrapper).text
    end

    def model_header=(value)
      within(model_header_wrapper) do
        find('.test-edit-icon', visible: true).click
        find('input').set(value)
      end
    end

    def model_body
      find(model_body_wrapper).text
    end

    def model_body=(value)
      within(model_body_wrapper) do
        find('.test-edit-icon', visible: true).click
        fill_in_froala(value)
      end
    end

    def passage_body=(value)
      within('.test-passage_wrapper') do
        find('.test-edit-icon', visible: true).click
        fill_in_froala(value)
      end
    end

    def model_header_wrapper
      '.test-reference-model .test-model-header-wrapper'
    end

    def model_body_wrapper
      '.test-reference-model .test-model-body-wrapper'
    end

    def delete
      control_bar = container.find('.section-references__controls')
      scroll_to(control_bar)
      within control_bar do
        find('.control-icon--delete', visible: true).click
      end
      within(container) do
        Waiter.new.wait do
          page.has_selector?('.assessment-controls__message-box.is-active')
        end
        Waiter.new.wait do
          page.has_selector?('.assessment-controls__message-box.is-active')
        end
        click_button('delete')
      end
    end
  end

  class QuestionElement
    include Capybara::DSL
    include CapybaraViewHelpers
    include RspecJsCommonHelpers

    attr_reader :question_number, :section

    def initialize(section, question_number)
      @section = section
      @question_number = question_number
    end

    def to_s
      "section(#{section.section_number}).question(#{question_number})"
    end

    def prompt
      prompt_wrapper.text
    end

    def prompt=(value)
      within(prompt_wrapper) do
        find('.test-edit-icon', visible: true).click
        fill_in_froala(value)
      end
    end

    def prompt_wrapper
      element_find_or_fail(container, '.assessment-question__prompt', "#{self}.prompt")
    end

    def visible?
      container.visible?
    end

    def edit
      control_bar = container.find('.test-control-bar-question')
      scroll_to(control_bar)
      within control_bar do
        find('a.test-button_edit').click
      end
    end

    def delete
      control_bar = container.find('.test-control-bar-question')
      scroll_to(control_bar)
      within control_bar do
        find('a.test-button_delete').click
        Waiter.new.wait do
          page.has_selector?('.assessment-controls__message-box.is-active')
        end
        # Confirm
        click_button('delete')
        Waiter.new.wait do
          page.has_no_selector?('.assessment-controls__message-box.is-active')
        end
      end
    end

    def save
      within(container) do
        scroll_to(first(:button, 'save'))
        first(:button, 'save').click
        sleep 1
      end
    end

    def move_up
      within(control_bar_wrapper) do
        page.execute_script('window.TESTMODE = true;')
        find('a.test-button-move-up').click
      end
      sleep 1
    end

    def move_down
      within(control_bar_wrapper) do
        page.execute_script('window.TESTMODE = true;')
        find('a.test-button-move-down').click
      end
      sleep 1
    end

    private def control_bar_wrapper
      element_find_nth_or_fail(
        section.container,
        '.test-control-bar-question',
        question_number - 1,
        "#{self}.control_bar"
      )
    end

    def choices
      selector = '.assessment-answers li.assessment-answers__item'
      container.all(selector).map.with_index(1) do |_choice, number|
        QuestionChoiceElement.new(self, number)
      end
    end

    def choice(number)
      QuestionChoiceElement.new(self, number)
    end

    def container
      element_find_nth_or_fail(
        section.container,
        '.assessment-question-wrapper',
        question_number - 1,
        self
      )
    end
  end

  class QuestionChoiceElement
    include Capybara::DSL
    include CapybaraViewHelpers
    include RspecJsCommonHelpers

    attr_reader :choice_number, :question

    def initialize(question, choice_number)
      @question = question
      @choice_number = choice_number
    end

    def to_s
      "#{question}.choice(#{choice_number})"
    end

    def prompt
      container.text
    end

    def prompt=(value)
      within(container) do
        find('.test-edit-icon', visible: true).click
        find('input[type="text"]').set(value)
      end
    end

    def container
      element_find_nth_or_fail(
        question.container,
        'li.assessment-answers__item',
        choice_number - 1,
        self
      )
    end
  end

  def for_instructor_created_assessment_page
    yield InstructorCreatedAssessmentPageObject.new
  end

  def questions_for_activity(activity)
    activity.items.select do |item|
      !item.is_a?(MaestroActivityEngine::ActivityContent::Reference::Base)
    end
  end

  def text_references_for_activity(activity)
    activity.items.select do |item|
      item.is_a?(MaestroActivityEngine::ActivityContent::Reference::Text)
    end
  end

  def click_new_assessment_menu_item
    expect(page).to have_selector(new_assessment_link_selector)
    find('.test-create-new-menu').hover
    find(new_assessment_link_selector).click
  end

  def create_assessment_with_content(lesson:, toc_location:, concept:, content_filepath:)
    assessment = create(
      :instructor_created_activity,
      lesson: lesson,
      toc_location: toc_location,
      concept: concept,
      cms_revision_id: 1,
      process_as_assessment: true,
      instructor: instructor
    )
    allow(Activity).to receive(:filepath_from_revision_id).and_return(content_filepath)
    assessment.save!
    assessment.content_json = assessment.generate_content_json
    assessment.save!
    assessment = Activity.find(assessment.id)
    assessment
  end

  def activity_question_counts(activity)
    activity.content_object.activities.map(&:question_count)
  end

  def activity_questions_numbers(activity)
    activity.content_object.activities.map do |sub_activity|
      sub_activity.questions.map(&:question_number)
    end
  end

  def activity_questions_ranks(activity)
    activity.content_object.activities.map do |sub_activity|
      sub_activity.questions.map(&:rank)
    end
  end

  def activity_references_ranks(activity)
    activity.content_object.activities.map do |sub_activity|
      references = sub_activity.items.select do |item|
        item.is_a?(MaestroActivityEngine::ActivityContent::Reference::Base)
      end
      references.map(&:rank)
    end
  end

  def get_reference(section, type)
    section.references.detect do |ref|
      ref.is_a?(eval("MaestroActivityEngine::ActivityContent::Reference::#{type}"))
    end
  end

  def activity_direction_lines(activity)
    activity.content_object.activities.map do |sub_activity|
      sub_activity.exam_reference.body.children.text
    end
  end

  def validate_sections_direction_lines(direction_lines)
    for_instructor_created_assessment_page do |pobject|
      direction_lines.each.with_index(1) do |dl, section_number|
        pobject.for_section(section_number) do |section|
          expect(section.direction_line).to eq(dl)
        end
      end
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
      within('.test-prompt-contents') do
        fill_in_froala(text)
      end
    end
  end

  let(:instructor) { create(:instructor) }
  let(:program) do
    create(:program).tap do |program|
      program.units = Array.new(3) do |number|
        create(
          :unit,
          name: "Lesson #{number + 1}",
          rank: number + 1,
          released: true,
          program: program
        )
      end
      program.units.each do |unit|
        unit.lessons = [
          create(
            :lesson,
            name: unit.name,
            rank: unit.rank,
            unit: unit,
            toc_entries: Array.new(5) do |index|
              # Create assessment strands and non assessment strands.
              create(:toc_entry, assessment: index < 3)
            end
          )
        ]
      end
      program.save!
    end
  end

  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.toc_entries.first }

  let(:concept) do
    create(
      :concept,
      assessment: true,
      singular_label: 'quiz',
      id: strand.location,
      lesson: lesson
    )
  end

  let(:exam_strand) { lesson.toc_entries[1] }

  let(:exam_concept) do
    create(
      :concept,
      assessment: true,
      singular_label: 'exam',
      id: exam_strand.location,
      lesson: lesson,
      name: exam_strand.title
    )
  end

  let(:course) { create(:course, owner: instructor, program: program) }
  let!(:section) { create(:section, course: course, instructor: instructor) }

  # IDs are needed here because those two values are defined in the
  # assessment XML fixture.
  let!(:media_items) do
    [
      create(
        :media_item_audio,
        id: 1,
        filename: 'vocab_list_audio_1.mp3',
        transcript: 'Audio file 1 transcription'
      ),
      create(:media_item_audio, id: 2, filename: 'vocab_list_audio_2.mp3')
    ]
  end

  let(:assessment) do
    create_assessment_with_content(
      lesson: lesson,
      toc_location: strand.location,
      concept: concept,
      content_filepath: File.join('spec', 'fixtures', 'xml', 'assessment.xml'),
      instructor: instructor
    )
  end

  let(:editable_assessment) do
    create_assessment_with_content(
      lesson: lesson,
      toc_location: strand.location,
      concept: concept,
      content_filepath: File.join(
        'spec', 'fixtures', 'xml', 'editable_assessment.xml'
      ),
      instructor: instructor
    )
  end

  let(:editable_multiple_choice_same) do
    create_assessment_with_content(
      lesson: lesson,
      toc_location: strand.location,
      concept: concept,
      content_filepath: File.join(
        'spec', 'fixtures', 'xml', 'editable_multiple_choice_same.xml'
      )
    )
  end

  let(:editable_assessment_with_2_sections) do
    create_assessment_with_content(
      lesson: lesson,
      toc_location: strand.location,
      concept: concept,
      content_filepath: File.join(
        'spec', 'fixtures', 'xml', 'assessment_with_2_sections.xml'
      )
    )
  end

  let(:editable_assessment_with_3_sections) do
    create_assessment_with_content(
      lesson: lesson,
      toc_location: strand.location,
      concept: concept,
      content_filepath: File.join(
        'spec', 'fixtures', 'xml', 'assessment_with_3_sections.xml'
      )
    )
  end

  let(:new_assessment_link_selector) { '.assessment_link' }

  context 'As an instructor' do
    let(:activity) do
      concept
      create_assessment_with_unit_lesson_concept(program, strand_id: strand.location)
    end

    before do
      allow(Maestro::LicenseGroup).to receive(:all).and_return([])
      admin = create(:institution_admin)
      create(:school_program_admin_user,
             user: admin,
             school: course.school,
             program: program,
             account_type: admin.account_type)
      give_instructor_access_to_toc(activity: activity)
      initialize_program_access_client_calls_for_instructor(instructor, program)
      log_in_as(instructor)
    end

    scenario 'As an instructor I can create a new custom assessment' do
      activity_title = 'My new assessment'
      activity_student_title = 'New assessment student title'
      section_title = 'My new section title'
      section_direction_line = 'My new section direction line'
      existing_assessment = create_activity_with_content(
        File.join(
          'spec', 'fixtures', 'xml', 'assessment_with_2_sections.xml'
        ),
        program,
        cms_revision_id: 1,
        concept: concept,
        lesson: lesson,
        strand_id: strand.location
      )

      purpose 'I cannot create a new assessment from the activities TOC' do
        # The 'Add content' menu is only displayed when at least one activity
        # exists
        create(
          :activity,
          lesson_id: lesson.id,
          concept: concept,
          activity_type: 'drop_down',
          toc_location: lesson.strands[0].location
        )

        visit instructor_toc_path(
          program,
          display_lesson: lesson.id,
          start_unit: lesson.unit.id,
          toc_location: activity.toc_location
        )

        expect(page).to have_no_selector(new_assessment_link_selector)
      end

      create(
        :activity,
        lesson_id: lesson.id,
        concept: exam_concept,
        toc_location: exam_strand.location
      )

      visit instructor_assessments_path(
        program,
        display_lesson: lesson.id,
        toc_location: exam_strand.location
      )

      # Go to the second strand.
      click_link(exam_strand.title)

      purpose 'I create a new assessment' do
        click_new_assessment_menu_item
      end

      purpose 'I can change the default title' do
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.activity_title).to eq('New assessment')
          pobject.activity_title = activity_title

          step 'I can use the accent bar' do
            first_accent_bar = AccentBar.characters('es')[0].first
            click_button(first_accent_bar)
            click_button(first_accent_bar)
            activity_title << first_accent_bar

            within('.activity-title') do
              page.first('.test-edit-icon', visible: true).click
            end

            expect(find('#activity_title').value).to eq activity_title
          end
        end
      end

      purpose 'I can change the default student title' do
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.activity_student_title).to eq(nil)
          pobject.activity_student_title = activity_student_title

          step 'I can use the accent bar' do
            first_accent_bar = AccentBar.characters('es')[0].first
            click_button(first_accent_bar)
            click_button(first_accent_bar)
            activity_student_title << first_accent_bar
            expect(find('#activity_student_title').value).to eq activity_student_title
          end
        end
      end

      purpose 'The assessment has zero section' do
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.sections).to eq([])
        end
      end

      purpose 'I can add a new section' do
        click_link('new content')
        for_instructor_created_assessment_page do |pobject|
          pobject.add_section(:free_response)

          # Wait for the newly added section to scroll into view.
          sleep(0.450)
          pobject.for_section(1) do |section|
            section.section_title = section_title
            section.direction_line = section_direction_line
            section.points_per_response = 3
            section.save_new_section
          end
        end
      end

      purpose 'I can add a new section using Existing Content' do
        click_link('existing content')

        within('.test-left-hand-well') do
          select(lesson.name, from: 'lesson_filter')

          click_link(existing_assessment.title)
        end

        wait_for_ajax
        expect(page).to have_content('Multiple choice activity header')
        click_button('Select All')
        click_button('Import')
      end

      step 'I save the assessment' do
        for_instructor_created_assessment_page do |pobject|
          expect do
            pobject.save_activity

            expect_flash_message(
              :notice,
              "Assessment #{activity_title} successfully created."
            )
          end.to change(Activity, :count).by(1)
        end
      end

      step 'I am redirected to the edit assessment page' do
        activity = Activity.last
        assessment_url = edit_instructor_created_activity_path(
          lesson_id: activity.lesson_id,
          toc_entry_id: activity.toc_location,
          program_id: activity.program.id,
          id: activity
        )
        expect_url(assessment_url)
      end

      purpose 'The assessment has been saved in the database' do
        assessment = Activity.last
        expect(assessment).to have_attributes(
          activity_type: 'exam',
          title: activity_title,
          lesson_id: lesson.id,
          toc_location: exam_strand.location.to_i,
          concept_id: exam_concept.id
        )
        expect(assessment.content_object.activities.count).to eq(3)
        section = assessment.content_object.activities[0]
        expect(section.exam_reference.header.content).to eq(section_title)
        expect(section.exam_reference.body.content).to eq(section_direction_line)
      end

      for_instructor_created_assessment_page do |pobject|
        pobject.exit_activity
        expect(page).to have_current_path(
          instructor_assessments_path(
            display_lesson: lesson.id,
            program_id: program.id,
            start_unit: lesson.unit.rank,
            toc_location: exam_strand.location
          )
        )
      end
    end

    scenario 'As an instructor I can create a new custom assessment and ' \
             'exit back to the assessment toc' do
      activity_title = 'My new assessment'

      visit instructor_assessments_path(
        program,
        display_lesson: activity.lesson_id,
        toc_location: activity.toc_location
      )

      purpose 'I create a new assessment' do
        click_new_assessment_menu_item
      end

      purpose 'I can change the default title' do
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.activity_title).to eq('New assessment')
          pobject.activity_title = activity_title
        end
      end

      purpose 'I cannot save when no sections have been added' do
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.sections).to eq([])
          pobject.save_activity
          expect(page).to have_selector(
            '.test-no-sections-modal',
            text: 'Assessment must include at least one section.'
          )
          click_button('Accept')
          find('.test-cancel-save-changes-modal-button').click
        end
      end

      purpose 'I cannot save and exit when no sections have been added' do
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.sections).to eq([])
          pobject.save_exit_activity
          expect(page).to have_selector(
            '.test-no-sections-modal',
            text: 'Assessment must include at least one section.'
          )
          click_button('Accept')
          find('.test-cancel-unsaved-changes-modal-button').click
        end
      end

      purpose 'I can add a new section' do
        click_link('new content')
        for_instructor_created_assessment_page do |pobject|
          pobject.add_section(:free_response)

          # Wait for the newly added section to scroll into view.
          sleep(0.450)
          pobject.for_section(1) do |section|
            section.section_title = 'Section title'
            section.direction_line = 'Section direction line'
            section.points_per_response = 3
            section.save_new_section
          end
        end
      end

      lesson_2 = program.units[1].lessons.first
      lesson_2_exam_strand = lesson_2.toc_entries[1]
      lesson_2_exam_concept = create(
        :concept,
        assessment: true,
        singular_label: 'exam',
        id: lesson_2_exam_strand.location,
        lesson: lesson_2,
        name: lesson_2_exam_strand.title
      )

      create(
        :activity,
        lesson_id: lesson_2.id,
        concept: lesson_2_exam_concept,
        toc_location: lesson_2_exam_strand.location
      )

      find('.test-assessment-location-edit-button').click
      select(lesson_2.name, from: 'lesson_filter')
      select(lesson_2_exam_strand.title, from: 'assessment_list_strand')
      sleep 1
      find('.test-assessment-location-save-button').click

      step 'I save the assessment' do
        for_instructor_created_assessment_page do |pobject|
          expect do
            pobject.save_exit_activity

            expect_flash_message(
              :notice,
              "Assessment #{activity_title} successfully created."
            )
          end.to change(Activity, :count).by(1)
        end
      end

      purpose 'I am redirected to the assessment toc for the newly ' \
              'selected lesson and strand' do
        expect_url(
          instructor_assessments_path(
            display_lesson: lesson_2.id,
            program_id: program.id,
            toc_location: lesson_2_exam_strand.location
          )
        )
        # byebug
        # expect(current_path).to eq(instructor_assessments_path(program))
      end
    end

    scenario 'I can create an editable version of a VHL assessment, ' \
             'clicking a "copy" link from assessments TOC' do
      visit instructor_assessments_path(
        program,
        display_lesson: activity.lesson_id,
        toc_location: activity.toc_location
      )

      copy_assessment_link = find("#copy_assessment_link_#{activity.id}")
      copy_assessment_link.click

      find('.js-save-changes', visible: true).click

      new_assessment_title = "Copy of #{activity.title}"
      expect(page).to have_selector('.activity_title', text: new_assessment_title)

      edit_link = find('.test-icon-edit')
      edit_link.click

      first_question = activity.content_object.activities.first.exam_reference.body.children.text
      activities_count = activity.content_object.activities.count
      expect(page).to have_selector('.test-assessment-block--section', count: activities_count)
      expect(page).to have_content(first_question)
    end

    scenario 'I can create an editable version of a VHL assessment (Angular bug), ' \
             'clicking a "copy" link from assessments TOC' do
      visit instructor_assessments_path(
        program,
        display_lesson: activity.lesson_id,
        toc_location: activity.toc_location
      )

      copy_assessment_link = find("#copy_assessment_link_#{activity.id}")
      copy_assessment_link.click

      find('.js-save-changes', visible: true).click

      new_assessment_title = "Copy of #{activity.title}"
      expect(page).to have_selector('.activity_title', text: new_assessment_title)

      # Find the instructor-created copy and modify its content_json.
      activity_copy = InstructorCreatedActivity.where(title: new_assessment_title).first
      instructor_revision = InstructorActivityRevision.find(activity_copy.instructor_revision_id)

      instructor_revision.content_json = File.open(
        File.join(
          'spec',
          'fixtures',
          'json',
          'multiple_choice_alternating_references_and_questions.json'
        ),
        &:readlines
      ).join('')

      instructor_revision.save!

      edit_link = find('.test-icon-edit')
      edit_link.click

      # Test for content.
      first_question = activity_copy
                       .content_object
                       .activities
                       .first
                       .exam_reference
                       .body
                       .children
                       .text

      expect(page).to have_content(first_question)

      # Test for correct numbering.
      (1..5).each do |question_number|
        expect(page).to have_selector('h3.dynamic-number--question', text: question_number.to_s)
      end
    end

    scenario 'As an instructor I can create a new solo video recording custom assessment' do
      svr_activity_title = 'SVR assessment'
      svr_section_title = 'SVR Section title'
      svr_section_dl = 'SVR Section direction line'

      visit instructor_assessments_path(
        program,
        display_lesson: activity.lesson_id,
        toc_location: activity.toc_location
      )

      purpose 'I create a new assessment' do
        click_new_assessment_menu_item
      end

      purpose 'I can change the default title' do
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.activity_title).to eq('New assessment')
          pobject.activity_title = svr_activity_title
        end
      end

      purpose 'I can add a new SVR section' do
        click_link('new content')
        for_instructor_created_assessment_page do |pobject|
          pobject.add_section(:solo_video_recording)

          # Wait for the newly added section to scroll into view.
          sleep(0.450)
          pobject.for_section(1) do |section|
            section.section_title = svr_section_title
            section.direction_line = svr_section_dl
            section.points_per_response = 3
            section.save_new_section
          end
        end
      end

      lesson_2 = program.units[1].lessons.first
      lesson_2_exam_strand = lesson_2.toc_entries[1]
      lesson_2_exam_concept = create(
        :concept,
        assessment: true,
        singular_label: 'exam',
        id: lesson_2_exam_strand.location,
        lesson: lesson_2,
        name: lesson_2_exam_strand.title
      )

      create(
        :activity,
        lesson_id: lesson_2.id,
        concept: lesson_2_exam_concept,
        toc_location: lesson_2_exam_strand.location
      )

      find('.test-assessment-location-edit-button').click
      select(lesson_2.name, from: 'lesson_filter')
      select(lesson_2_exam_strand.title, from: 'assessment_list_strand')
      sleep 1
      find('.test-assessment-location-save-button').click

      step 'I save the assessment' do
        for_instructor_created_assessment_page do |pobject|
          expect do
            pobject.save_activity

            expect_flash_message(
              :notice,
              "Assessment #{svr_activity_title} successfully created."
            )
          end.to change(Activity, :count).by(1)
        end
      end

      step 'I am redirected to the edit assessment page' do
        activity = Activity.last
        assessment_url = edit_instructor_created_activity_path(
          lesson_id: activity.lesson_id,
          toc_entry_id: activity.toc_location,
          program_id: activity.program.id,
          id: activity
        )
        expect_url(assessment_url)
      end

      purpose 'The SVR assessment has been saved in the database' do
        assessment = Activity.last
        expect(assessment).to have_attributes(
          activity_type: 'exam',
          title: svr_activity_title,
        )
        expect(assessment.content_object.activities.count).to eq(1)
        section = assessment.content_object.activities[0]
        expect(section.exam_reference.header.content).to eq(svr_section_title)
        expect(section.exam_reference.body.content).to eq(svr_section_dl)
      end
    end

    scenario 'As an instructor I can create a new fill in the blanks custom assessment' do
      fib_activity_title = 'FIB assessment'
      fib_section_title = 'FIB Section title'
      fib_section_dl = 'FIB Section direction line'

      visit instructor_assessments_path(
        program,
        display_lesson: activity.lesson_id,
        toc_location: activity.toc_location
      )

      purpose 'I create a new assessment' do
        click_new_assessment_menu_item
      end

      purpose 'I can change the default title' do
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.activity_title).to eq('New assessment')
          pobject.activity_title = fib_activity_title
        end
      end

      purpose 'I can add a new FIB section' do
        click_link('new content')
        for_instructor_created_assessment_page do |pobject|
          pobject.add_section(:fill_in_the_blanks)
          # Wait for the newly added section to scroll into view.
          sleep(0.450)
          pobject.for_section(1) do |section|
            section.section_title = fib_section_title
            section.direction_line = fib_section_dl
            section.points_per_response = 2
            purpose 'I can use WOL size feature' do
              step 'I can see the WOL size dropdown' do
                expect(page).to have_selector('.test-wol-size-select-wrapper', visible: true)
              end
              step 'I can change the WOL size to small' do
                find('.test-wol-size-select').select('Small')
              end
            end
            purpose 'I can edit the FIB question' do
              step 'I can see a "Add blank" button' do
                expect(page).to have_selector('.test-add-blank-button', text: 'Add blank')
              end
              step 'I can see a "Add text" button' do
                expect(page).to have_selector('.test-add-text-button', text: 'Add text')
              end
              step 'Add blank' do
                add_blank('Buenos días.')
              end
              step 'Add text' do
                add_text('—Buenos días. ¿Qué tal?')
              end
            end
            section.save_new_section
          end
        end
      end

      lesson_2 = program.units[1].lessons.first
      lesson_2_exam_strand = lesson_2.toc_entries[1]
      lesson_2_exam_concept = create(
        :concept,
        assessment: true,
        singular_label: 'exam',
        id: lesson_2_exam_strand.location,
        lesson: lesson_2,
        name: lesson_2_exam_strand.title
      )

      create(
        :activity,
        lesson_id: lesson_2.id,
        concept: lesson_2_exam_concept,
        toc_location: lesson_2_exam_strand.location
      )

      find('.test-assessment-location-edit-button').click
      select(lesson_2.name, from: 'lesson_filter')
      select(lesson_2_exam_strand.title, from: 'assessment_list_strand')
      sleep 1
      find('.test-assessment-location-save-button').click

      step 'I save the assessment' do
        for_instructor_created_assessment_page do |pobject|
          expect do
            pobject.save_activity

            expect_flash_message(
              :notice,
              "Assessment #{fib_activity_title} successfully created."
            )
          end.to change(Activity, :count).by(1)
        end
      end

      step 'I am redirected to the edit assessment page' do
        activity = Activity.last
        assessment_url = edit_instructor_created_activity_path(
          lesson_id: activity.lesson_id,
          toc_entry_id: activity.toc_location,
          program_id: activity.program.id,
          id: activity
        )
        expect_url(assessment_url)
      end

      purpose 'The FIB assessment has been saved in the database' do
        assessment = Activity.last
        expect(assessment).to have_attributes(
          activity_type: 'exam',
          title: fib_activity_title,
        )
        expect(assessment.content_object.activities.count).to eq(1)
        section = assessment.content_object.activities[0]
        expect(section.exam_reference.header.content).to eq(fib_section_title)
        expect(section.exam_reference.body.content).to eq(fib_section_dl)
      end
    end

    scenario 'As an instructor I can create a new external link custom assessment' do
      external_link_activity_title = 'External Link assessment'
      external_link_section_title = 'External Link Section title'
      external_link_section_dl = 'External Link Section direction line'
      external_link_url = 'https://external-link-1.com'
      
      new_list_reference_header = 'New list reference header'
      new_list_reference_body = '<ol><li>item 1</li><li>item 2</li></ol>'
      new_table_reference_caption = 'new table reference caption'
      new_table_reference_body ='<table><thead><tr><th>Header</th>' \
        '</tr></thead><tbody><tr><td>Cell 1</td></tr><tr><td>Cell 2</td>' \
        '</tr></tbody></table>'
      new_model_reference_header = 'New model reference header'
      new_model_reference_body = 'New model reference body'

      visit instructor_assessments_path(
        program,
        display_lesson: activity.lesson_id,
        toc_location: activity.toc_location
      )

      purpose 'I create a new assessment' do
        click_new_assessment_menu_item
      end

      purpose 'I can change the default title' do
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.activity_title).to eq('New assessment')
          pobject.activity_title = external_link_activity_title
        end
      end

      purpose 'I can add a new External Link section with references' do
        click_link('new content')
        for_instructor_created_assessment_page do |pobject|
          pobject.add_section(:external_link)

          # Wait for the newly added section to scroll into view.
          sleep(0.450)
          pobject.for_section(1) do |section|
            section.section_title = external_link_section_title
            section.direction_line = external_link_section_dl
            section.points_per_response = 1
            section.external_link_url = external_link_url

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

            purpose 'I can add a model reference' do
              section.add_section_reference('model')
              section.section_reference(1).model_header = new_model_reference_header
              section.section_reference(1).model_body = new_model_reference_body
            end

            purpose 'I can add a passage reference' do
              section.add_section_reference('passage')
              step 'I can see the Reference type not permitted warning dialog' do
                expect(page).to have_selector(
                  '.test-warning-message',
                  text: 'A section can have either a single passage reference ' \
                  'or a mix of any other types of references.'
                )
              end

              step 'Click "OK" to confirm the warning dialog' do
                find('.test-confirm-warning-btn').click
              end

              step 'Click "trash icon" to delete the existing model reference' do
                within('.section-references') do
                  find('.test-reference-delete-link', visible: true).click
                  find('.test-confirm-delete', visible: true).click
                end
              end

              step 'Create a new passage reference' do
                section.add_section_reference('passage')
                section.section_reference(1).passage_body = 'passage reference body text'
              end
            end

            section.save_new_section

            within('.test-passage_wrapper') do
              expect(page).to have_content('passage reference body text')
            end

            # Add list, table and model references
            purpose 'I can remove passage reference and add other references' do 
              step 'I can click edit section button' do
                within('.assessment-section-wrapper') do
                  find('.test-button_edit', visible: true).click
                end 
              end

              step 'I can remove passage reference' do
                within('.section-references') do
                  find('.test-reference-delete-link', visible: true).click
                  find('.test-confirm-delete', visible: true).click
                end
              end

              purpose 'I can add other references' do
                step 'I can add list reference in section' do
                  section.add_section_reference('list')
                  section.section_reference(1).list_header = new_list_reference_header
                  section.section_reference(1).list_body = new_list_reference_body
                end
    
                step 'I can add table reference in section' do
                  section.add_section_reference('table')
                  section.section_reference(1).table_caption = new_table_reference_caption
                  section.section_reference(1).table_body = new_table_reference_body
                end

                step 'I can add model reference in section' do
                  section.add_section_reference('model')
                  section.section_reference(1).model_header = new_model_reference_header
                  section.section_reference(1).model_body = new_model_reference_body
                end
              end
            end

            section.save_existing_section
          end
        end
      end

      lesson_2 = program.units[1].lessons.first
      lesson_2_exam_strand = lesson_2.toc_entries[1]
      lesson_2_exam_concept = create(
        :concept,
        assessment: true,
        singular_label: 'exam',
        id: lesson_2_exam_strand.location,
        lesson: lesson_2,
        name: lesson_2_exam_strand.title
      )

      create(
        :activity,
        lesson_id: lesson_2.id,
        concept: lesson_2_exam_concept,
        toc_location: lesson_2_exam_strand.location
      )

      find('.test-assessment-location-edit-button').click
      select(lesson_2.name, from: 'lesson_filter')
      select(lesson_2_exam_strand.title, from: 'assessment_list_strand')
      sleep 1
      find('.test-assessment-location-save-button').click

      step 'I save the assessment' do
        for_instructor_created_assessment_page do |pobject|
          expect do
            pobject.save_activity

            expect_flash_message(
              :notice,
              "Assessment #{external_link_activity_title} successfully created."
            )
          end.to change(Activity, :count).by(1)
        end
      end

      step 'I am redirected to the edit assessment page' do
        activity = Activity.last
        assessment_url = edit_instructor_created_activity_path(
          lesson_id: activity.lesson_id,
          toc_entry_id: activity.toc_location,
          program_id: activity.program.id,
          id: activity
        )
        expect_url(assessment_url)
      end

      purpose 'The External Link assessment has been saved in the database' do
        assessment = Activity.last
        expect(assessment).to have_attributes(
          activity_type: 'exam',
          title: external_link_activity_title,
        )
        expect(assessment.content_object.activities.count).to eq(1)
        section = assessment.content_object.activities[0]
        expect(section.exam_reference.header.content).to eq(external_link_section_title)
        expect(section.exam_reference.body.content).to eq(external_link_section_dl)
        expect(section.external_link_url).to eq(external_link_url)

        list_reference = get_reference(section, 'List')
        expect(list_reference.header.text).to eq('New list reference header')
        expect(list_reference.body.text).to include('item 1').and include('item 2')

        model_reference = get_reference(section, 'Model')
        expect(model_reference.header.text).to eq('New model reference header')
        expect(model_reference.body.text).to eq('New model reference body')

        table_reference = get_reference(section, 'Table')
        expect(table_reference.caption.content).to include('new table reference caption')
        expect(table_reference.body.text).to include('Cell 1').and include('Cell 2')
      end
    end

    scenario 'As an instructor I can create a new upload file custom assessment' do
      upload_file_activity_title = 'Upload File assessment'
      upload_file_section_title = 'Upload File Section title'
      upload_file_section_dl = 'Upload File Section direction line'

      visit instructor_assessments_path(
        program,
        display_lesson: activity.lesson_id,
        toc_location: activity.toc_location
      )

      purpose 'I create a new assessment' do
        click_new_assessment_menu_item
      end

      purpose 'I can change the default title' do
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.activity_title).to eq('New assessment')
          pobject.activity_title = upload_file_activity_title
        end
      end

      purpose 'I can visit a new upload file activity section' do
        click_link('new content')
        for_instructor_created_assessment_page do |pobject|
          pobject.add_section(:upload_file)

          # Wait for the newly added section to scroll into view.
          sleep(0.450)
          pobject.for_section(1) do |section|
            section.section_title = upload_file_section_title
            section.direction_line = upload_file_section_dl
            section.points_per_response = 1

            step 'I can see link to upload file button' do
              expect(page).to have_selector(
                '.test-label-for-upload-file-btn',
                text: 'Choose File'
              )
            end
          end
        end
      end
    end

    context 'When canceling the addition of an assessment' do
      scenario 'returns to the assessment view' do
        visit instructor_assessments_path(
          program,
          display_lesson: activity.lesson_id,
          toc_location: activity.toc_location
        )

        click_new_assessment_menu_item

        for_instructor_created_assessment_page do |pobject|
          expect do
            pobject.exit_activity
            expect(current_path).to eq(instructor_assessments_path(program))
          end
        end
      end
    end

    def focus_select_section(section)
      find('#focus_indicator').click
      within('#focus_menu_container') { click_link(section.name) }
    end

    context 'Course focus' do
      let!(:section_2) do
        create(:section, course: course, instructor: instructor, name: 'Section_2')
      end

      scenario 'Edit and copy options should be visible' do
        visit instructor_assessments_path(
          program,
          display_lesson: activity.lesson_id,
          toc_location: activity.toc_location
        )
        copy_assessment_link = find("#copy_assessment_link_#{activity.id}")
        copy_assessment_link.click

        find('.js-save-changes', visible: true).click

        expect(page).to have_selector('.test-icon-edit')
        expect(page).to have_selector('.test-icon-copy')

        focus_select_section(section_2)

        expect(page).to have_selector('.test-icon-edit')
        expect(page).to have_selector('.test-icon-copy')
      end

      scenario 'Delete option should not be visible' do
        visit(instructor_assessments_path(program))
        focus_select_section(section_2)
        expect(page).to have_no_selector('.test-icon-remove')
      end

      scenario 'Edit link should be visible in the assessment show' do
        visit instructor_assessments_path(
          program,
          display_lesson: activity.lesson_id,
          toc_location: activity.toc_location
        )
        copy_assessment_link = find("#copy_assessment_link_#{activity.id}")
        copy_assessment_link.click

        find('.js-save-changes', visible: true).click

        click_link("Copy of #{activity.title}")
        expect(page).to have_selector('.edit-created-activity')
        visit(instructor_assessments_path(program))
        focus_select_section(section_2)
        click_link("Copy of #{activity.title}")
        expect(page).to have_selector('.edit-created-activity')
      end
    end

    context 'Activity is not an exam' do
      before do
        activity.update_column(:activity_type, 'opend_ended')
      end

      scenario 'Copy icon should only appear for exams' do
        visit instructor_assessments_path(
          program,
          display_lesson: activity.lesson_id,
          toc_location: activity.toc_location
        )
        expect(page).to have_no_css('.test-icon-copy')
        activity.update_column(:activity_type, 'exam')
        visit instructor_assessments_path(program)
        expect(page).to have_css('.test-icon-copy')
      end
    end

    scenario 'I can edit multiple-choice same with more than two answers' do
      activity = editable_multiple_choice_same

      activity_path = edit_instructor_created_activity_path(
        lesson_id: activity.lesson_id,
        toc_entry_id: activity.toc_location,
        program_id: program.id,
        id: activity.id
      )
      give_instructor_access_to_toc
      initialize_program_access_client_calls_for_instructor(instructor, program)
      allow(Maestro::LicenseGroup).to receive(:all).and_return([])

      visit activity_path

      # Edit a section
      for_instructor_created_assessment_page do |pobject|
        pobject.for_section(1) do |section|
          section.edit

          # edit the answers
          section.for_question(1) do |question|
            expect(question.choice(1).prompt).to include('answer 1')
            expect(question.choice(2).prompt).to include('answer 2')
            expect(question.choice(3).prompt).to include('answer 3')

            choice_2_container = question.choice(2).container
            within(choice_2_container) do
              click_link('Edit')
              find('input[type="text"]').set('new answer')
              click_link('Edit')
            end

            expect(question.choice(2).prompt).to include('new answer')

            # Choice 3 shouldn't change when choice 2 is edited
            expect(question.choice(3).prompt).to include('answer 3')
          end

          # When the choice for one question is edited, the choices for
          # the other questions in the sections get updated to match.
          section.for_question(2) do |question|
            expect(question.choice(2).prompt).to include('new answer')

            # Choice 3 shouldn't change when choice 2 is edited
            expect(question.choice(3).prompt).to include('answer 3')
          end

          # Add a question
          section.add_question

          # Ensure the newly added question has had time to render
          Waiter.new.wait do
            within section.container do
              page.all('.assessment-question-wrapper').size == 3
            end
          end

          section.for_question(3) do |question|
            question.prompt = 'new question prompt'
            expect(question.choice(1).prompt).to include('answer 1')

            # Expect the choices for the new question to reflect the edits
            # to the existing choices.
            expect(question.choice(2).prompt).to include('new answer')
            # Choice 3 shouldn't be a duplicate of choice 2.
            expect(question.choice(3).prompt).to include('answer 3')
          end

          section.save_existing_section
        end
      end
    end

    context 'Editing an activity', test_debt: true do
      let(:activity) { editable_assessment }

      def activity_path(activity)
        edit_instructor_created_activity_path(
          lesson_id: activity.lesson_id,
          toc_entry_id: activity.toc_location,
          program_id: program.id,
          id: activity.id
        )
      end

      before do
        give_instructor_access_to_toc
        initialize_program_access_client_calls_for_instructor(instructor, program)
        allow(Maestro::LicenseGroup).to receive(:all).and_return([])
      end

      scenario 'Redirect to My content after editing an activity if it comes from My content' do
        activity_path_from_my_content = edit_instructor_created_activity_path(
          lesson_id: lesson.id,
          toc_entry_id: strand.location,
          program_id: program.id,
          id: activity.id,
          from_my_content: true
        )
        visit(activity_path_from_my_content)
        for_instructor_created_assessment_page do |pobject|
          pobject.save_activity
        end
        expect(current_path).to eq(instructor_mycontent_path(program))
      end

      scenario 'I can remove questions from a section' do
        questions = questions_for_activity(activity.content_object.activities[0])
        question_prompt = questions.first.prompt.text
        expect(activity.content_object.activities.map(&:question_count)).to eq(
          [5, 3, 2, 3, 4]
        )

        visit(activity_path(activity))

        for_instructor_created_assessment_page do |pobject|
          pobject.for_section(1) do |section|
            section.edit
            section.question(1).delete
            section.save_existing_section
          end
        end

        step 'I save the activity' do
          for_instructor_created_assessment_page do |pobject|
            pobject.save_activity
          end
        end

        step 'I see a success message' do
          expect_flash_message(:notice, "Activity #{activity.title} has been updated")
        end

        purpose 'the data model has been updated' do
          edited_activity = Activity.find(activity.id)

          step 'The question has been removed' do
            questions = questions_for_activity(edited_activity.content_object.activities[0])
            questions.each do |question|
              expect(question.prompt.text).not_to eq(question_prompt)
            end
          end

          step 'The questions count have been updated' do
            expect(activity_question_counts(edited_activity)).to eq(
              [4, 3, 2, 3, 4]
            )
          end

          step 'The questions have been re-indexed' do
            expect(activity_questions_numbers(edited_activity)).to eq(
              [
                [1, 2, 3, 4],
                [1, 2, 3],
                [1, 2],
                [1, 2, 3],
                [1, 2, 3, 4]
              ]
            )
          end

          step 'The questions have been re-ranked' do
            expect(activity_questions_ranks(edited_activity)).to eq(
              [
                [1, 2, 3, 4],
                [5, 6, 7],
                [8, 9],
                [10, 11, 12],
                [13, 14, 15, 16]
              ]
            )
          end

          step 'the references have been re-ranked' do
            # Every activity has at least one reference, the direction line.
            # Section 1 has 2 text reference and section 2 and 3 have an
            # additional audio reference.
            expect(activity_references_ranks(edited_activity)).to eq(
              [[1, 2, 3], [4, 5], [6, 7], [8], [9]]
            )
          end
        end
      end

      scenario 'I can add questions to a section' do
        prompts = questions_for_activity(
          activity.content_object.activities[0]
        ).map { |question| question.prompt.text }
        expect(activity.content_object.activities.map(&:question_count)).to eq(
          [5, 3, 2, 3, 4]
        )

        visit(activity_path(activity))

        for_instructor_created_assessment_page do |pobject|
          expect(pobject.section(1).questions.map(&:prompt)).to eq(
            prompts
          )
        end

        purpose 'I can add a question' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(1) do |section|
              section.edit
              section.add_question
              section.for_question(6) do |question|
                question.prompt = 'new question prompt'
                question.choice(1).prompt = 'choice 1'
                question.choice(2).prompt = 'choice 2'
                question.choice(3).prompt = 'choice 3'
              end
              section.save_existing_section
            end
          end

          for_instructor_created_assessment_page do |pobject|
            pobject.section(1).for_question(6) do |question|
              expect(question.prompt).to eq('new question prompt')
              expect(question.choices.map(&:prompt)).to eq(
                ['choice 1', 'choice 2', 'choice 3']
              )
            end
          end
        end

        step 'I save the activity' do
          for_instructor_created_assessment_page do |pobject|
            pobject.save_activity
          end
        end

        step 'I see a success message' do
          expect_flash_message(:notice, "Activity #{activity.title} has been updated")
        end

        purpose 'the data model has been updated' do
          edited_activity = Activity.find(activity.id)

          step 'The new question has been saved' do
            question = questions_for_activity(edited_activity.content_object.activities[0])[5]

            expect(question.prompt.text).to eq(
              'new question prompt'
            )
            expect(question.choices.map(&:text)).to eq(
              ['choice 1', 'choice 2', 'choice 3']
            )
          end

          step 'The questions count have been updated' do
            expect(activity_question_counts(edited_activity)).to eq(
              [6, 3, 2, 3, 4]
            )
          end

          step 'The questions have been re-indexed' do
            expect(activity_questions_numbers(edited_activity)).to eq(
              [
                [1, 2, 3, 4, 5, 6],
                [1, 2, 3],
                [1, 2],
                [1, 2, 3],
                [1, 2, 3, 4]
              ]
            )
          end

          step 'The questions have been re-ranked' do
            expect(activity_questions_ranks(edited_activity)).to eq(
              [
                [1, 2, 3, 4, 5, 6],
                [7, 8, 9],
                [10, 11],
                [12, 13, 14],
                [15, 16, 17, 18]
              ]
            )
          end

          step 'the references have not been re-ranked' do
            expect(activity_references_ranks(edited_activity)).to eq(
              activity_references_ranks(activity)
            )
          end
        end
      end

      scenario 'I can reorder questions' do
        prompts = questions_for_activity(
          activity.content_object.activities[0]
        ).map { |question| question.prompt.text }

        visit(activity_path(activity))
        for_instructor_created_assessment_page do |pobject|
          expect(pobject.section(1).questions.map(&:prompt)).to eq(
            prompts
          )
        end

        purpose 'I can move down a question' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(1) do |section|
              section.edit
              section.question(1).move_down
              section.save_existing_section
            end
          end

          for_instructor_created_assessment_page do |pobject|
            expect(pobject.section(1).questions.map(&:prompt)).to eq(
              [prompts[1], prompts[0], prompts[2], prompts[3], prompts[4]]
            )
          end
        end

        purpose 'I can move down a question' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(1) do |section|
              section.edit
              section.question(2).move_down
              section.save_existing_section
            end
          end

          for_instructor_created_assessment_page do |pobject|
            expect(pobject.section(1).questions.map(&:prompt)).to eq(
              [prompts[1], prompts[2], prompts[0], prompts[3], prompts[4]]
            )
          end
        end

        purpose 'I can move up a question' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(1) do |section|
              section.edit
              section.question(3).move_up
              section.save_existing_section
            end
          end

          for_instructor_created_assessment_page do |pobject|
            expect(pobject.section(1).questions.map(&:prompt)).to eq(
              [prompts[1], prompts[0], prompts[2], prompts[3], prompts[4]]
            )
          end
        end

        step 'I save the activity' do
          for_instructor_created_assessment_page do |pobject|
            pobject.save_activity
          end
        end

        step 'I see a success message' do
          expect_flash_message(:notice, "Activity #{activity.title} has been updated")
        end

        purpose 'the data model has been updated' do
          edited_activity = Activity.find(activity.id)

          step 'The questions have been reordered' do
            reordered_questions_prompts = questions_for_activity(
              edited_activity.content_object.activities[0]
            ).map { |question| question.prompt.text }
            expect(reordered_questions_prompts).to eq(
              [prompts[1], prompts[0], prompts[2], prompts[3], prompts[4]]
            )
          end

          step 'The questions have been re-indexed' do
            expect(activity_questions_numbers(edited_activity)).to eq(
              [
                [1, 2, 3, 4, 5],
                [1, 2, 3],
                [1, 2],
                [1, 2, 3],
                [1, 2, 3, 4]
              ]
            )
          end

          step 'The questions have been re-ranked' do
            expect(activity_questions_ranks(edited_activity)).to eq(
              [
                [1, 2, 3, 4, 5],
                [6, 7, 8],
                [9, 10],
                [11, 12, 13],
                [14, 15, 16, 17]
              ]
            )
          end

          step 'the references have not been re-ranked' do
            expect(activity_references_ranks(edited_activity)).to eq(
              activity_references_ranks(activity)
            )
          end
        end
      end

      scenario 'I can reorder sections' do
        visit(activity_path(activity))
        dls = activity_direction_lines(activity)

        validate_sections_direction_lines(dls)

        purpose 'I can move down a section' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(1) do |section|
              section.move_down
            end
          end

          dls = dls.insert(1, dls.delete_at(0))
          validate_sections_direction_lines(dls)
        end

        purpose 'I can move down a section' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(2) do |section|
              section.move_down
            end
          end

          dls = dls.insert(2, dls.delete_at(1))
          validate_sections_direction_lines(dls)
        end

        purpose 'I can move up a section' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(5) do |section|
              section.move_up
            end
          end

          dls = dls.insert(3, dls.delete_at(4))
          validate_sections_direction_lines(dls)
        end

        step 'I save the activity' do
          for_instructor_created_assessment_page do |pobject|
            pobject.save_activity
          end
        end

        step 'I see a success message' do
          expect_flash_message(:notice, "Activity #{activity.title} has been updated")
        end

        purpose 'the data model has been updated' do
          edited_activity = Activity.find(activity.id)

          step 'The sections have been reordered' do
            expect(activity_direction_lines(edited_activity)).to eq(dls)
          end

          step 'The questions have been re-indexed' do
            expect(activity_questions_numbers(edited_activity)).to eq(
              [
                [1, 2, 3],
                [1, 2],
                [1, 2, 3, 4, 5],
                [1, 2, 3, 4],
                [1, 2, 3]
              ]
            )
          end

          step 'The questions have been re-ranked' do
            expect(activity_questions_ranks(edited_activity)).to eq(
              [
                [1, 2, 3],
                [4, 5],
                [6, 7, 8, 9, 10],
                [11, 12, 13, 14],
                [15, 16, 17]
              ]
            )
          end

          step 'the references have been re-ranked' do
            # Every activity has at least one reference, the direction line.
            # Section 1 has 2 text reference and section 2 and 3 have an
            # additional audio reference.
            expect(activity_references_ranks(edited_activity)).to eq(
              [[1, 2], [3, 4], [5, 6, 7], [8], [9]]
            )
          end
        end
      end

      scenario 'I can edit the assessment' do
        new_assessment_title = 'This is a new title'
        new_title = 'new section title'
        new_direction_line = 'new direction line'
        new_text_reference_header = 'new text reference header'
        new_text_reference_body = 'new text reference body'

        visit(activity_path(activity))

        purpose 'I see the assessment title' do
          for_instructor_created_assessment_page do |pobject|
            expect(pobject.activity_title).to eq(activity.title)
            expect(pobject.activity_title_info).to eq(
              "Students will see: #{activity.lesson_name} | #{activity.concept_name}"
            )
          end
        end

        purpose 'I see section information' do
          subactivity = activity.content_object.activities[0]
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(1) do |section|
              expect(section.section_title).to eq(
                subactivity.exam_reference.header.content
              )
              expect(section.direction_line).to eq(
                subactivity.exam_reference.body.content
              )
            end
          end
        end

        purpose 'I can edit the assessment title' do
          for_instructor_created_assessment_page do |pobject|
            pobject.activity_title = new_assessment_title
          end
        end

        purpose 'I can edit the section information' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(1) do |section|
              section.edit
              section.section_title = new_title
              section.direction_line = new_direction_line
              section.points_per_response = 3
              section.save_existing_section
            end
          end
        end

        subactivity = activity.content_object.activities[0]
        text_references = text_references_for_activity(subactivity)
        purpose 'I see section references' do
          for_instructor_created_assessment_page do |pobject|
            pobject.section(1).for_section_reference(1) do |reference|
              # null header must be displayed as an empty string
              expect(reference.text_header).to eq('')
              expect(reference.text_body).to eq(text_references[0].body.children.text)
            end

            pobject.section(1).for_section_reference(2) do |reference|
              expect(reference.text_header).to eq(text_references[1].header.children.text)
              expect(reference.text_body).to eq(text_references[1].body.children.text)
            end
          end
        end

        purpose 'I can delete a section reference' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(1) do |section|
              section.edit
              section.section_reference(2).delete
              section.save_existing_section
            end
          end
        end

        purpose 'The section reference has been deleted' do
          for_instructor_created_assessment_page do |pobject|
            expect(pobject.section(1).section_references.map(&:text_body)).to eq(
              [text_references[0].body.children.text]
            )
          end
        end

        purpose 'I can edit a section reference' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(1) do |section|
              section.edit
              section.section_reference(1).text_header = new_text_reference_header
              section.section_reference(1).text_body = new_text_reference_body
              section.save_existing_section
            end
          end
        end

        step 'I save the activity' do
          for_instructor_created_assessment_page do |pobject|
            pobject.save_activity
          end
        end

        step 'I see a success message' do
          expect_flash_message(:notice, "Activity #{new_assessment_title} has been updated")
        end

        purpose 'the new information are displayed' do
          visit(activity_path(activity))
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(1) do |section|
              expect(section.section_title).to eq(new_title)
              expect(section.direction_line).to eq(new_direction_line)
            end
          end
        end

        purpose 'the information have been updated in the data model' do
          edited_activity = Activity.find(activity.id)
          subactivity = edited_activity.content_object.activities[0]
          expect(subactivity.exam_reference.header.content).to eq(
            new_title
          )
          expect(subactivity.exam_reference.body.content).to eq(
            new_direction_line
          )

          text_references = text_references_for_activity(subactivity)
          expect(text_references.count).to eq(1)
          expect(text_references[0].header.children.text).to eq(new_text_reference_header)
          expect(text_references[0].body.children.text).to eq(new_text_reference_body)

          # Since we edited the number of points per question for section 1,
          # The points possible for the whole assessment has been updated.
          expect(edited_activity.points_possible).to eq(67)
          expect(questions_for_activity(subactivity).map(&:points_possible)).to eq(
            [3, 3, 3, 3, 3]
          )
        end
      end

      scenario 'I can delete a section' do
        subactivity = activity.content_object.activities[2]
        section_title = subactivity.exam_reference.header.content
        direction_line = subactivity.exam_reference.body.content

        visit(activity_path(activity))

        purpose 'I can delete a section' do
          for_instructor_created_assessment_page do |pobject|
            pobject.for_section(3) do |section|
              expect(section.section_title).to eq(section_title)
              expect(section.direction_line).to eq(direction_line)
              section.delete
            end
          end
        end

        step 'I see a success message' do
          expect(page).to have_selector('.assessment-actions__content', text: 'section deleted.')
        end

        purpose 'The section has been removed (is not visible)' do
          for_instructor_created_assessment_page do |pobject|
            expect(pobject.section(3)).not_to be_visible
          end
        end

        step 'I save the activity' do
          for_instructor_created_assessment_page do |pobject|
            pobject.save_activity
          end
        end

        step 'I see a success message' do
          expect_flash_message(:notice, "Activity #{activity.title} has been updated")
        end

        purpose 'the data model has been updated' do
          edited_activity = Activity.find(activity.id)

          step 'The section has been removed' do
            direction_lines = activity_direction_lines(activity)
            direction_lines.delete_at(2)
            expect(activity_direction_lines(edited_activity)).to eq(
              direction_lines
            )
          end

          step 'The questions count have been updated' do
            expect(activity_question_counts(edited_activity)).to eq(
              [5, 3, 3, 4]
            )
          end

          step 'The questions have been re-indexed' do
            expect(activity_questions_numbers(edited_activity)).to eq(
              [
                [1, 2, 3, 4, 5],
                [1, 2, 3],
                [1, 2, 3],
                [1, 2, 3, 4]
              ]
            )
          end

          step 'The questions have been re-ranked' do
            expect(activity_questions_ranks(edited_activity)).to eq(
              [
                [1, 2, 3, 4, 5],
                [6, 7, 8],
                [9, 10, 11],
                [12, 13, 14, 15]
              ]
            )
          end

          step 'the references have been re-ranked' do
            # Every activity has at least one reference, the direction line.
            # Section 1 has 2 text reference and section 2 has an additional
            # audio reference.
            expect(activity_references_ranks(edited_activity)).to eq(
              [[1, 2, 3], [4, 5], [6], [7]]
            )
          end
        end
      end

      scenario 'I can add a new section' do
        activity_count = activity.content_object.activities.count
        section_title = 'new section title'
        direction_line = 'new section direction line'

        visit(activity_path(activity))

        purpose 'I see all the sections' do
          for_instructor_created_assessment_page do |pobject|
            expect(pobject.sections.count).to eq(activity_count)
          end
        end

        purpose 'I can add a new section' do
          for_instructor_created_assessment_page do |pobject|
            pobject.add_section(:free_response)

            pobject.for_section(1) do |section|
              section.section_title = section_title
              section.direction_line = direction_line
              section.points_per_response = 3
              section.save_new_section
            end
          end
        end

        step 'I save the activity' do
          for_instructor_created_assessment_page do |pobject|
            pobject.save_activity
          end
        end

        step 'I see a success message' do
          expect_flash_message(:notice, "Activity #{activity.title} has been updated")
        end

        visit(activity_path(activity))

        purpose 'the new section is displayed' do
          for_instructor_created_assessment_page do |pobject|
            expect(pobject.sections.count).to eq(activity_count + 1)
            pobject.for_section(1) do |section|
              expect(section.section_title).to eq(section_title)
              expect(section.direction_line).to eq(direction_line)
            end
          end
        end

        purpose 'the data model has been updated' do
          edited_activity = Activity.find(activity.id)

          step 'The new section has been added' do
            subactivity = edited_activity.content_object.activities[0]
            expect(subactivity.exam_reference.header.content).to eq(
              section_title
            )
            expect(subactivity.exam_reference.body.content).to eq(
              direction_line
            )
          end

          step 'The questions count have been updated' do
            expect(activity_question_counts(edited_activity)).to eq(
              [1, 5, 3, 2, 3, 4]
            )
          end

          step 'The questions have been re-indexed' do
            expect(activity_questions_numbers(edited_activity)).to eq(
              [
                [1],
                [1, 2, 3, 4, 5],
                [1, 2, 3],
                [1, 2],
                [1, 2, 3],
                [1, 2, 3, 4]
              ]
            )
          end

          step 'The questions have been re-ranked' do
            expect(activity_questions_ranks(edited_activity)).to eq(
              [
                [1],
                [2, 3, 4, 5, 6],
                [7, 8, 9],
                [10, 11],
                [12, 13, 14],
                [15, 16, 17, 18]
              ]
            )
          end

          step 'the references have been re-ranked' do
            # Every activity has at least one reference, the direction line.
            # Section 1 has 2 text reference and section 2 and 3 have an
            # additional audio reference.
            expect(activity_references_ranks(edited_activity)).to eq(
              [[1], [2, 3, 4], [5, 6], [7, 8], [9], [10]]
            )
          end
        end
      end

      context 'Shuffling an assessment' do
        scenario 'I can shuffle sections' do
          activity = editable_assessment_with_2_sections
          visit(activity_path(activity))

          direction_lines = activity_direction_lines(activity)
          questions_prompts = questions_for_activity(
            activity.content_object.activities[0]
          ).map { |question| question.prompt.text }

          for_instructor_created_assessment_page do |pobject|
            expect(pobject.sections.map(&:direction_line)).to eq(
              direction_lines
            )
          end

          purpose 'I can use the shuffle sections button to reorder the sections' do
            for_instructor_created_assessment_page do |pobject|
              pobject.shuffle_sections
            end
          end

          purpose 'The sections have been shuffled' do
            for_instructor_created_assessment_page do |pobject|
              expect(pobject.sections.map(&:direction_line)).to eq(
                [direction_lines[1], direction_lines[0]]
              )
            end
          end

          purpose 'I can change the sections order back to the original order' do
            for_instructor_created_assessment_page do |pobject|
              pobject.section(1).move_down
            end
          end

          purpose 'The sections are back to the original order' do
            for_instructor_created_assessment_page do |pobject|
              expect(pobject.sections.map(&:direction_line)).to eq(
                direction_lines
              )
            end
          end

          purpose 'I can use the shuffle sections button to reorder the sections again' do
            for_instructor_created_assessment_page do |pobject|
              pobject.shuffle_sections
            end
          end

          purpose 'The sections have been shuffled' do
            for_instructor_created_assessment_page do |pobject|
              expect(pobject.sections.map(&:direction_line)).to eq(
                [direction_lines[1], direction_lines[0]]
              )
            end
          end

          step 'I save the activity' do
            for_instructor_created_assessment_page do |pobject|
              pobject.save_activity
            end
          end

          step 'I see a success message' do
            expect_flash_message(:notice, "Activity #{activity.title} has been updated")
          end

          purpose 'the data model has been updated' do
            edited_activity = Activity.find(activity.id)

            step 'The sections have been reordered' do
              reordered_direction_lines = edited_activity.content_object.activities.map do |activity|
                activity.exam_reference.body.children.text
              end
              expect(reordered_direction_lines).to eq(
                [direction_lines[1], direction_lines[0]]
              )
            end

            step 'The questions count have been updated' do
              expect(activity_question_counts(edited_activity)).to eq(
                [3, 2]
              )
            end

            step 'The questions have been re-indexed' do
              expect(activity_questions_numbers(edited_activity)).to eq(
                [
                  [1, 2, 3],
                  [1, 2]
                ]
              )
            end

            step 'The questions have been re-ranked' do
              expect(activity_questions_ranks(edited_activity)).to eq(
                [
                  [1, 2, 3],
                  [4, 5]
                ]
              )
            end

            step 'the references have been re-ranked' do
              expect(activity_references_ranks(edited_activity)).to eq(
                [[1], [2, 3, 4]]
              )
            end
          end
        end

        scenario 'I can shuffle questions' do
          activity = editable_assessment_with_2_sections
          questions_prompts = questions_for_activity(
            activity.content_object.activities[0]
          ).map { |question| question.prompt.text }

          visit(activity_path(activity))

          for_instructor_created_assessment_page do |pobject|
            expect(pobject.section(1).questions.map(&:prompt)).to eq(
              [questions_prompts[0], questions_prompts[1]]
            )
          end

          purpose 'I can use the shuffle questions button to reorder the questions' do
            for_instructor_created_assessment_page do |pobject|
              pobject.section(1).shuffle_questions
            end
          end

          purpose 'The questions have been shuffled' do
            for_instructor_created_assessment_page do |pobject|
              expect(pobject.section(1).questions.map(&:prompt)).to eq(
                [questions_prompts[1], questions_prompts[0]]
              )
            end
          end

          purpose 'I can change the questions order back to the original order' do
            for_instructor_created_assessment_page do |pobject|
              pobject.for_section(1) do |section|
                section.edit
                section.question(1).move_down
                section.save_existing_section
              end
            end
          end

          purpose 'The questions are back to the original order' do
            for_instructor_created_assessment_page do |pobject|
              expect(pobject.section(1).questions.map(&:prompt)).to eq(
                questions_prompts
              )
            end
          end

          purpose 'I can use the shuffle questions button to reorder the questions again' do
            for_instructor_created_assessment_page do |pobject|
              pobject.section(1).shuffle_questions
            end
          end

          step 'I save the activity' do
            for_instructor_created_assessment_page do |pobject|
              pobject.save_activity
            end
          end

          step 'I see a success message' do
            expect_flash_message(:notice, "Activity #{activity.title} has been updated")
          end

          purpose 'the data model has been updated' do
            edited_activity = Activity.find(activity.id)

            step 'The questions have been reordered' do
              shuffled_questions = questions_for_activity(
                edited_activity.content_object.activities[0]
              )
              expect(shuffled_questions.map { |question| question.prompt.text }).to eq(
                [questions_prompts[1], questions_prompts[0]]
              )
            end

            step 'The questions count have been updated' do
              expect(activity_question_counts(edited_activity)).to eq(
                [2, 3]
              )
            end

            step 'The questions have been re-indexed' do
              expect(activity_questions_numbers(edited_activity)).to eq(
                [
                  [1, 2],
                  [1, 2, 3]
                ]
              )
            end

            step 'The questions have been re-ranked' do
              expect(activity_questions_ranks(edited_activity)).to eq(
                [
                  [1, 2],
                  [3, 4, 5]
                ]
              )
            end

            step 'the references have been re-ranked' do
              expect(activity_references_ranks(edited_activity)).to eq(
                [[1, 2, 3], [4]]
              )
            end
          end
        end

        scenario 'I can shuffle sections after deleting a section' do
          activity = editable_assessment_with_3_sections
          direction_lines = activity_direction_lines(activity)

          visit(activity_path(activity))

          for_instructor_created_assessment_page do |pobject|
            expect(pobject.sections.map(&:direction_line)).to eq(
              direction_lines
            )
          end

          purpose 'I can delete a section' do
            for_instructor_created_assessment_page do |pobject|
              pobject.for_section(2) do |section|
                section.delete
              end
            end
          end

          purpose 'The section has been removed (is not visible)' do
            for_instructor_created_assessment_page do |pobject|
              expect(pobject.section(2)).not_to be_visible
            end
          end

          purpose 'I can use the shuffle sections button to reorder the sections' do
            for_instructor_created_assessment_page do |pobject|
              pobject.shuffle_sections
            end
          end

          purpose 'The sections have been shuffled' do
            for_instructor_created_assessment_page do |pobject|
              expect(pobject.sections.select(&:visible?).map(&:direction_line)).to eq(
                [direction_lines[2], direction_lines[0]]
              )
            end
          end

          step 'I save the activity' do
            for_instructor_created_assessment_page do |pobject|
              pobject.save_activity
            end
          end

          step 'I see a success message' do
            expect_flash_message(:notice, "Activity #{activity.title} has been updated")
          end

          purpose 'the data model has been updated' do
            edited_activity = Activity.find(activity.id)

            step 'The sections have been reordered' do
              expect(activity_direction_lines(edited_activity)).to eq(
                [direction_lines[2], direction_lines[0]]
              )
            end

            step 'The questions count have been updated' do
              expect(activity_question_counts(edited_activity)).to eq(
                [2, 3]
              )
            end

            step 'The questions have been re-indexed' do
              expect(activity_questions_numbers(edited_activity)).to eq(
                [
                  [1, 2],
                  [1, 2, 3]
                ]
              )
            end

            step 'The questions have been re-ranked' do
              expect(activity_questions_ranks(edited_activity)).to eq(
                [
                  [1, 2],
                  [3, 4, 5]
                ]
              )
            end

            step 'the references have been re-ranked' do
              expect(activity_references_ranks(edited_activity)).to eq(
                [[1], [2, 3, 4]]
              )
            end
          end
        end

        scenario 'I can shuffle questions after deleting a question' do
          activity = editable_assessment_with_3_sections
          questions_prompts = questions_for_activity(
            activity.content_object.activities[0]
          ).map { |question| question.prompt.text }

          visit(activity_path(activity))

          purpose 'I see all the questions' do
            for_instructor_created_assessment_page do |pobject|
              expect(pobject.section(1).questions.map(&:prompt)).to eq(
                questions_prompts
              )
            end
          end

          purpose 'I delete a question' do
            for_instructor_created_assessment_page do |pobject|
              pobject.for_section(1) do |section|
                section.edit
                section.question(2).delete
                section.save_existing_section
              end
            end
          end

          purpose 'The question has been deleted (is not visible)' do
            for_instructor_created_assessment_page do |pobject|
              expect(pobject.section(1).questions.select(&:visible?).map(&:prompt)).to eq(
                [questions_prompts[0], questions_prompts[2]]
              )
            end
          end

          purpose 'I can use the shuffle questions button to reorder the questions' do
            for_instructor_created_assessment_page do |pobject|
              pobject.for_section(1) do |section|
                section.edit
                section.shuffle_questions
                section.save_existing_section
              end
            end
          end

          purpose 'The questions have been shuffled' do
            for_instructor_created_assessment_page do |pobject|
              expect(pobject.section(1).questions.select(&:visible?).map(&:prompt)).to eq(
                [questions_prompts[2], questions_prompts[0]]
              )
            end
          end

          step 'I save the activity' do
            for_instructor_created_assessment_page do |pobject|
              pobject.save_activity
            end
          end

          step 'I see a success message' do
            expect_flash_message(:notice, "Activity #{activity.title} has been updated")
          end

          purpose 'the data model has been updated' do
            edited_activity = Activity.find(activity.id)

            step 'The questions have been reordered' do
              edited_questions_prompts = questions_for_activity(
                edited_activity.content_object.activities[0]
              ).map { |question| question.prompt.text }
              expect(edited_questions_prompts).to eq(
                [questions_prompts[2], questions_prompts[0]]
              )
            end

            step 'The questions count have been updated' do
              expect(activity_question_counts(edited_activity)).to eq(
                [2, 3, 2]
              )
            end

            step 'The questions have been re-indexed' do
              expect(activity_questions_numbers(edited_activity)).to eq(
                [
                  [1, 2],
                  [1, 2, 3],
                  [1, 2]
                ]
              )
            end

            step 'The questions have been re-ranked' do
              expect(activity_questions_ranks(edited_activity)).to eq(
                [
                  [1, 2],
                  [3, 4, 5],
                  [6, 7]
                ]
              )
            end

            step 'the references have been re-ranked' do
              expect(activity_references_ranks(edited_activity)).to eq(
                [[1, 2, 3], [4], [5]]
              )
            end
          end
        end
      end
    end
  end

  context 'As a student' do
    let(:student) { create(:student) }
    let(:activity) { assessment }
    let(:activity_data) { ActivityTest::ActivityData::MultiType.new(activity, nil) }
    let(:fake_submissions) { {} }

    before do
      initialize_fake_submissions_client
      allow(Maestro::LicenseGroup).to receive(:all).and_return(
        [double('LicenseGroup', id: 1, name: '01-Supersite')]
      )

      initialize_program_access_client_calls_for_user_and_program(student, program)
      give_user_access_to_program(student, program)

      student.sections << section
      CourseLibraryActivity.create(course: course, activity: activity, hidden: false)
      create(
        :assignment,
        section: section,
        show_at: 1.day.ago,
        due_date: 2.days.from_now.to_date,
        assignable: activity,
        grade_availability: :on_grading
      )
      log_in_as(student)
    end

    xscenario 'I can view and submit an activity' do
      pending 'Failing for unknown reasons related to release MAE-76241'
      visit section_activity_path(
        id: activity.id,
        section_id: section.id,
        begin_work: true
      )

      step 'I answer all the questions' do
        for_preview_page(activity_data) do
          activity_data.sub_activity(1).questions.each do |question|
            from_multiple_choice_question(question.question_number).select_choice(1)
          end
        end
      end

      step 'I submit the activity' do
        for_preview_page(activity_data) do
          click_button_expect_alert(:submit, '18 questions are unanswered.')
        end

        step 'I see a success message' do
          expect_flash_message(
            :notice,
            'Your instructor has chosen not to allow students to view their ' \
            'full results for this activity until all students have been graded.'
          )
        end
      end
    end
  end
end
