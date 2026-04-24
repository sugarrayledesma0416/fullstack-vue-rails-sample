feature 'Instructor assessments', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  include WaitForAjax
  # Include application helpers for time formatting methods
  include ApplicationHelper

  let(:school) { create(:school) }
  let(:program) { create(:vol_program, title: 'My Program') }
  let(:program_settings) do
    {
      allow_assessments_randomization: 'true',
      course_setup_descriptions: {
        express_course: '<b>Express</b> course description',
        advanced_course: '<b>Advanced</b> course description',
        learning_tracks: {
          header: 'Learning tracks',
          general: 'General learning track description.',
          options_overall: 'Learning track options description.',
          options: [
            {
              label: 'Essentials',
              explanation: 'What option 1 covers'
            },
            {
              label: 'Complete',
              explanation: 'What option 2 covers'
            }
          ]
        }
      }
    }
  end
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:unit_1) { create(:unit, program: program, name: 'Lesson 1', rank: 0) }
  let(:unit_2) { create(:unit, program: program, name: 'Lesson 2', rank: 0) }
  let(:unit_3) { create(:unit, program: program, name: 'Lesson 3', rank: 2) }
  let(:unit_4) { create(:unit, program: program, name: 'Lesson 4', rank: 3) }
  let(:strand_titles) do
    [
      'Vocabulary Quizzes',
      'Grammar Quizzes',
      'Lesson Tests'
    ]
  end
  let(:component_1) { 'Quiz 1' }
  let(:component_2) { 'Quiz 2' }
  let!(:lesson_1) do
    toc_entries = Array.new(2) do |index|
      create(:assessment_toc_entry, title: strand_titles[index])
    end
    create(
      :lesson,
      unit: unit_1,
      name: 'Lesson 1',
      toc_entries: toc_entries
    ).tap do |lesson|
      create_concept_for_toc_entries(lesson)
    end
  end
  let!(:lesson_2) do
    toc_entries = Array.new(3) do |index|
      create(:assessment_toc_entry, title: strand_titles[index])
    end
    create(
      :lesson,
      unit: unit_2,
      name: 'Lesson 2',
      toc_entries: toc_entries
    ).tap do |lesson|
      create_concept_for_toc_entries(lesson)
    end
  end
  let(:course) do
    create(
      :course,
      program: program,
      school: school,
      owner: instructor,
      first_unit_id: unit_1.id,
      last_unit_id: unit_3.id
    )
  end
  let(:course_licenses) { [] }
  let(:section_1) do
    create(
      :section,
      course: course,
      instructor: instructor,
      name: 'section 1',
      time_zone: 'Eastern Time (US & Canada)'
    )
  end
  let(:section_2) do
    create(
      :section,
      course: course,
      instructor: instructor,
      name: 'section 2',
      time_zone: 'Pacific Time (US & Canada)'
    )
  end
  let(:category) { create(:category, course: course) }
  let(:valid_due_date) { course.end_date - 1.day }
  let(:valid_release_date) { valid_due_date - 1.day }
  let(:valid_result_availability_date) { valid_release_date + 2.days }

  def create_assignment(activity, attrs)
    create(
      :assignment,
      {
        assignable: activity,
        category: category
      }.merge(attrs)
    )
  end

  def create_assigned_assessment(assignment, attrs = {})
    create(
      :assigned_assessment_detail,
      assignment: assignment,
      time_limit: attrs[:time_limit],
      number_of_attempts: attrs[:number_of_attempts],
      password: attrs[:password]
    )
  end

  def create_assessment(attrs = {})
    strand = attrs[:lesson].toc_entries.first
    concept = create_concept_matching_strand_id(
      strand, attrs.slice(:lesson, :program)
    )
    create(
      :activity,
      {
        toc_location: strand.location,
        activity_type: 'exam',
        grading_method: 'mixed',
        concept: concept,
        randomizable: false
      }.merge(attrs)
    )
  end

  before do
    allow(Maestro::LicenseGroup).to receive(:all).and_return(
      [instance_double('LicenseGroup', id: 1, name: '01-Supersite')]
    )
    course_licenses << Maestro::CourseLicense.new('license_group' => { 'id' => 1, 'demo' => false })
    allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)

    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  class InstructorAssessmentsPageObject
    include Capybara::DSL
    include CapybaraViewHelpers
    include RspecJsCommonHelpers

    def show_all_activities
      select('All Activities', from: 'visibility_selector')
      # Click somewhere else to close the dropdown
      find('.c-heading--page-title').click
    end

    def show_only_assigned_activities
      select('Assigned Only', from: 'visibility_selector')
      # Click somewhere else to close the dropdown
      find('.c-heading--page-title').click
    end

    def components
      selector = '[data-container="component_header"]'
      page.all(selector).map.with_index(1) do |_element, number|
        ComponentPageElement.new(self, number)
      end
    end

    def component(component_number)
      ComponentPageElement.new(self, component_number)
    end

    def assign_button
      AssignButton.new
    end

    class AssignButton
      include Capybara::DSL
      include CapybaraViewHelpers

      delegate :click, to: :element

      def enabled?
        !disabled?
      end

      def disabled?
        element[:class].include?('hidden_helper')
      end

      def element
        find_or_fail('.instructor-action-bar a.assign-activities', self)
      end
    end
  end

  class ComponentPageElement
    include CapybaraViewHelpers

    attr_reader :page_object, :component_number

    def initialize(page_object, component_number)
      @page_object = page_object
      @component_number = component_number
    end

    def to_s
      "component(#{component_number})"
    end

    def activities
      container.all('.test-activity_entry', visible: true).map.with_index(1) do |_element, number|
        ActivityEntryPageElement.new(self, number)
      end
    end

    def activity(activity_number)
      ActivityEntryPageElement.new(self, activity_number)
    end

    def select_all_activities
      all_activities_checkbox.set(true)
    end

    def unselect_all_activities
      all_activities_checkbox.set(false)
    end

    def all_activities_checkbox
      element_find_or_fail(container, '.checkbox_all', "#{self}.all_activitiers_checkbox")
    end

    def title
      container.find('.toc_location_component').text
    end

    def has_nothing_assigned?
      container.has_selector?('.test-nothing-assigned')
    end

    def container
      selector = '[data-container="component_header"]'
      page_object.find_nth_or_fail(selector, component_number - 1, self)
    end

    class ActivityEntryPageElement
      include CapybaraViewHelpers

      attr_reader :component, :activity_number

      def initialize(component, activity_number)
        @component = component
        @activity_number = activity_number
      end

      def title
        element_find_or_fail(
          container, '.activity_link', "#{self}.title"
        ).text
      end

      def checkbox
        element_find_or_fail(
          container, '.toc-checkbox-col .toc_checkbox', "#{self}.checkbox"
        )
      end

      def due_date
        element_find_or_fail(
          container, '.toc_location_activity_due_date', "#{self}.due_date"
        ).text
      end

      def availability
        element_find_or_fail(
          container, '.release_date_time .assess_available_time', "#{self}.availability"
        ).text
      end

      def availability_date
        element_find_or_fail(
          container, '.release_date_time .available_specifics', "#{self}.availability_date"
        ).text
      end

      def result_availability
        element_find_or_fail(
          container, '.grade_availability_time .grade_available_time', "#{self}.result_availability"
        ).text
      end

      def result_availability_date
        element_find_or_fail(
          container, '.grade_availability_time .available_specifics', "#{self}.result_availability_date"
        ).text
      end

      def password_protected
        element_find_or_fail(
          container, '.password-protected-value', "#{self}.password_protected"
        ).text
      end

      def time_limit
        element_find_or_fail(
          container, '.time-limit-value', "#{self}.time_limit"
        ).text
      end

      def attempts_number
        element_find_or_fail(
          container, '.number-of-attempts-value', "#{self}.attempts_number"
        ).text
      end

      def randomize
        element_find_or_fail(
          container, '.randomize_per_student_value', "#{self}.randomize_per_student"
        ).text
      end

      def has_no_randomize_option?
        container.has_no_selector?('.randomize_per_student_value')
      end

      def has_no_properties?
        container.has_no_selector?('.c-property-list')
      end

      def container
        element_find_nth_or_fail(
          component.container, '.test-activity_entry', activity_number - 1, self
        )
      end
    end
  end

  class AssignmentOptionsModal
    include Capybara::DSL
    include CapybaraViewHelpers

    def due_date=(value)
      element_find_or_fail(
        content_container, 'input#activity_assignment_due_date', "#{self}.due_date"
      ).set(format_calendar_date(value))
      close_date_picker_control
    end

    def time_limit=(value)
      element_find_or_fail(
        content_container,
        'input#activity_assignment_assigned_assessment_detail_attributes_time_limit',
        "#{self}.time_limit"
      ).set(value)
      close_date_picker_control
    end

    def release_date=(value)
      element_find_or_fail(
        content_container,
        'input#activity_assignment_show_at',
        "#{self}.release_date"
      ).set(format_calendar_date(value))
      close_date_picker_control
    end

    def result_availability_date=(value)
      element_find_or_fail(
        content_container,
        'input#activity_assignment_grades_available_at',
        "#{self}.result_availability_date"
      ).set(format_calendar_date(value))
      close_date_picker_control
    end

    def password=(value)
      password_element.set(value)
    end

    def password
      password_element.value
    end

    def has_no_randomize_per_student_option?
      content_container.has_no_selector?(
        '#activity_assignment_randomize_per_student'
      )
    end

    def randomize_per_student=(value)
      content_container.select(
        value,
        from: 'activity_assignment_randomize_per_student'
      )
    end

    def format_calendar_date(value)
      if value.is_a?(Date)
        value.strftime('%m/%d/%Y')
      elsif value.is_a?(Time)
        value.strftime('%m/%d/%Y %I:%M %P')
      else
        value
      end
    end

    private def password_element
      element_find_or_fail(
        content_container,
        'input#activity_assignment_assigned_assessment_detail_attributes_password',
        "#{self}.password"
      )
    end

    def has_error?(error)
      container.has_selector?('.error_for_modal', exact_text: error)
    end

    def cancel_button
      element_find_or_fail(content_container, '.cancel_link button', "#{self}.cancel_button")
    end

    def reassign_cancel_button
      element_find_or_fail(review_content_container, '.cancel_link button', "#{self}.cancel_button")
    end

    def unassign_button
      element_find_or_fail(review_content_container, '.unassign_link button', "#{self}.unassign_button")
    end

    def reassign_button
      element_find_or_fail(review_content_container, '.reassign_link button', "#{self}.reassign_button")
    end

    def save_button
      page.all('.link_savechanges button')[1]
    end

    def container
      find('.ui-dialog .assignables_dialog')
    end

    def content_container
      find('.ui-dialog .assignables_dialog [data-container="reassign"]')
    end

    def assignables_container
      find('.ui-dialog .assignables_dialog [data-container="assignables"]')
    end

    def review_content_container
      find('.ui-dialog .assignables_dialog [data-container="review"]')
    end

    private def close_date_picker_control
      # click elsewhere to close the date picker
      container.click
      # wait for the date picker fade out animation to finish
      Waiter.new.wait do
        page.has_no_selector?('.ui-datepicker', visible: true)
      end
    end

    def assignable_details(assignable_number)
      AssignableDetailsPageElement.new(self, assignable_number)
    end

    def assignables_details
      selector = '[data-container="assignables"] tbody tr'
      page.all(selector).map.with_index(1) do |_element, number|
        AssignableDetailsPageElement.new(self, number)
      end
    end

    class AssignableDetailsPageElement
      include CapybaraViewHelpers

      attr_reader :modal, :assignable_number

      def initialize(modal, assignable_number)
        @modal = modal
        @assignable_number = assignable_number
      end

      def title
        element_find_or_fail(
          container,
          '[data-assignable-title]',
          "#{self}.title"
        ).text
      end

      def category
        element_find_or_fail(
          container,
          '[data-assignable-category]',
          "#{self}.category"
        ).text
      end

      def due_date
        element_find_or_fail(
          container,
          '[data-assignable-due_date]',
          "#{self}.due_date"
        ).text
      end

      private def container
        element_find_nth_or_fail(
          modal.assignables_container,
          'tbody tr',
          assignable_number - 1,
          self
        )
      end
    end
  end

  def for_instructor_assessment_page
    pobject = InstructorAssessmentsPageObject.new
    yield pobject if block_given?
    pobject
  end

  def for_assignment_options_modal
    modal = AssignmentOptionsModal.new
    yield modal if block_given?
    modal
  end

  def focus_select_section(section)
    find('#focus_indicator').click
    within('#focus_menu_container') { click_link(section.name) }
  end

  def create_concept_for_toc_entries(lesson)
    lesson.strands.each_with_index do |strand, index|
      create_concept_matching_strand_id(
        strand,
        name: strand.title,
        rank: index,
        assessment: true,
        lesson: lesson,
        program: program
      )
    end
  end

  def validate_activity_tooltip(activity)
    find("#activity_#{activity.id}").hover
    within("[data-hover-container='activity_#{activity.id}']") do
      expect(page).to have_selector('.activity_title', text: activity.title)
      expect(page).to have_selector('.activity_name', text: activity.student_title)
      expect(page).to have_selector(
        '.activity_type', text: "Total Questions = #{activity.question_summary_count}"
      )
      expect(page).to have_selector(
        '.points_possible', text: "Points possible: #{activity.points_possible}"
      )
      activity.content_summary.each do |type, count|
        expect(page).to have_selector(
          '[data-activity-count]', text: "#{count} #{Activity.humanize_activity_type(type)}"
        )
      end
    end
  end

  def google_classroom_column_visible
    expect(page).to have_selector('.test-col-gc-share')
  end

  def google_classroom_column_not_visible
    expect(page).to have_no_selector('.test-col-gc-share')
  end

  def google_classroom_button_visible_in_all_activities
    all_activities = all('.test-activity_entry')
    expect(all_activities).not_to be_empty
    all_activities.each do |activity|
      within(activity) do
        expect(page).to have_selector('.test-google-classroom-btn iframe')
      end
    end
  end

  def google_classroom_button_not_visible_in_all_activities
    all_activities = all('.test-activity_entry')
    expect(all_activities).not_to be_empty
    all_activities.each do |activity|
      within(activity) do
        expect(page).to have_no_selector('.test-google-classroom-btn')
      end
    end
  end

  xscenario 'Instructor assessment implementation', clear_session_storage: true do
    activity_1_1_1 = create_assessment(
      title: 'activity_1_1_1',
      content_summary: { dropdown: 6, open_ended: 2 }.to_json,
      points_possible: 26,
      component_name: component_1,
      student_title: 'student title 1',
      lesson: lesson_1
    )
    activity_1_1_2 = create_assessment(
      title: 'activity_1_1_2',
      content_summary: { multiple_choice: 2, open_ended: 1, fill_in_the_blanks: 2 }.to_json,
      points_possible: 30,
      component_name: component_1,
      student_title: 'student title 2',
      lesson: lesson_1,
      randomizable: true
    )
    activity_1_2_1 = create_assessment(
      title: 'activity_1_2_1',
      content_summary: { multiple_choice: 1, open_ended: 1 }.to_json,
      points_possible: 11,
      component_name: component_2,
      student_title: 'student title 3',
      lesson: lesson_1,
      randomizable: false
    )
    activity_1_2_1_assignment_1 = create_assignment(
      activity_1_2_1,
      section: section_1,
      grade_availability: :on_grading
    ).tap do |assignment|
      create_assigned_assessment(
        assignment,
        time_limit: 150,
        number_of_attempts: 2,
        password: 'password'
      )
    end
    activity_1_2_1_assignment_2 = create_assignment(
      activity_1_2_1,
      section: section_2,
      grade_availability: :on_grading
    ).tap do |assignment|
      create_assigned_assessment(
        assignment,
        time_limit: 150,
        number_of_attempts: 1
      )
    end
    activity_1_2_2 = create_assessment(
      title: 'activity_1_2_2',
      content_summary: { multiple_choice: 1, open_ended: 1, fill_in_the_blank: 2 }.to_json,
      points_possible: 16,
      component_name: component_2,
      lesson: lesson_1,
      randomizable: true
    )
    activity_1_2_2_assignment = create_assignment(
      activity_1_2_2,
      section: section_1,
      due_date: 4.days.ago.to_date,
      show_at: 2.days.ago.to_datetime,
      grade_availability: :on_specific_date,
      grades_available_at: 1.days.ago.to_datetime,
      randomize_per_student: true
    ).tap do |assignment|
      create_assigned_assessment(
        assignment,
        number_of_attempts: -1
      )
    end
    ProgramConfig.create!(
      program_settings.merge(
        program_id: program.id,
        creator_id: instructor.id
      )
    )

    purpose 'I can browse through lessons and strand' do
      visit instructor_assessments_path(program)

      purpose 'When selecting a new lesson containing a strand with the same name ' \
        'as the current selected strand, the strand is automatically selected' do
        step 'Select lesson "Lesson 1"' do
          find('.js-ls-dropdown-button-item').click
          find('.test-ls-dropdown-list-item', text: lesson_1.name).click
        end

        step 'Select strand "Grammar Quizzes"' do
          click_link('Grammar Quizzes')
        end

        step 'Select lesson "Lesson 2"' do
          find('.js-ls-dropdown-button-item').click
          find('.test-ls-dropdown-list-item', text: lesson_2.name).click
        end

        step 'I see the strand "Grammar Quizzes" selected' do
          within('li.c-vtabset__tab.is-selected') do
            expect(page).to have_css('.test-strand.parent', text: 'Grammar Quizzes')
          end
        end
      end

      purpose 'When selecting a new lesson that does not contain a strand with the same name ' \
        'as the current selected strand, the first strand is automatically selected' do
        step 'Select strand "Lesson Tests"' do
          find('a.test-strand.parent', text: 'Lesson Tests').click
        end

        step 'Select lesson "Lesson 1"' do
          find('.js-ls-dropdown-button-item').click
          find('.test-ls-dropdown-list-item', text: lesson_1.name).click
        end

        step 'I see the strand "Vocabulary Quizzes" selected' do
          within('li.c-vtabset__tab.is-selected') do
            expect(page).to have_css('.test-strand.parent', text: 'Vocabulary Quizzes')
          end
        end
      end
    end

    purpose 'I can choose to see only assigned activities' do
      step 'Select "Assigned Only" from the dropdown' do
        find('.js-visibility-selector').click
        find('.test-visibility-assigned', text: 'Assigned Only').click
      end

      step 'I only see assigned activities' do
        expect(page).to have_selector('.test-visibility-assigned', text: 'Assigned Only')
      end
    end

    purpose 'I can see a list of activities for that program' do
      step 'I see the name of the selected strand in the header' do
        expect(page).to have_selector(
          '.activities .selectedLesson',
          text: lesson_1.toc_entries.first.title
        )
      end

      step 'I choose to see all the activities' do
        for_instructor_assessment_page do |pobject|
          pobject.show_all_activities
        end
      end

      purpose 'I see all activities grouped by component' do
        step 'I see component 1 and component 2' do
          for_instructor_assessment_page do |pobject|
            expect(pobject.components.map(&:title)).to eq(
              [component_1, component_2]
            )
          end
        end

        purpose 'I see all activities information for component 1' do
          with_element(for_instructor_assessment_page.component(1)) do |component|
            expect(component.activities.map(&:title)).to eq(
              [activity_1_1_1.title, activity_1_1_2.title]
            )

            step 'I see activity_1_1_1' do
              with_element(component.activity(1)) do |activity|
                expect(activity.checkbox).not_to be_checked

                step 'I see no due date' do
                  expect(activity.due_date).to eq('')
                end

                step 'I see no assignment properties' do
                  expect(activity).to have_no_properties
                end

                step 'I see a tooltip with a complete summary' do
                  validate_activity_tooltip(activity_1_1_1)
                end
              end
            end

            step 'I see activity_1_1_2' do
              with_element(component.activity(2)) do |activity|
                expect(activity.checkbox).not_to be_checked

                step 'I see no due date' do
                  expect(activity.due_date).to eq('')
                end

                step 'I see no assignment properties' do
                  expect(activity).to have_no_properties
                end

                step 'I see a tooltip with a complete summary' do
                  validate_activity_tooltip(activity_1_1_2)
                end
              end
            end
          end
        end

        purpose 'I see all activities information for component 2' do
          with_element(for_instructor_assessment_page.component(2)) do |component|
            expect(component.activities.map(&:title)).to eq(
              [activity_1_2_1.title, activity_1_2_2.title]
            )

            step 'I see activity_1_2_1' do
              with_element(component.activity(1)) do |activity|
                expect(activity.checkbox).not_to be_checked

                step 'I see "varies" as a due date because the assessment has ' \
                     'multiple assignments with different due dates' do
                  expect(activity.due_date).to eq('varies')
                end

                step 'I see assignment details' do
                  step 'I see the availability details' do
                    expect(activity.availability).to eq('No')
                    expect(activity.availability_date).to eq('')
                  end

                  step 'I see the result availability details' do
                    expect(activity.result_availability).to eq('Yes')
                    expect(activity.result_availability_date).to eq('After grading')
                  end

                  step 'I see "varies" for the password protection because not ' \
                       'all assignments have the same password protection' do
                    expect(activity.password_protected).to eq('Varies')
                  end

                  step 'I see the assessment time limit' do
                    expect(activity.time_limit).to start_with('2 hours 30 minutes')
                  end

                  step 'I see the maximum number of attempts of all the ' \
                       'assignments for this assessment' do
                    expect(activity.attempts_number).to eq('2')
                  end

                  step 'I do not see the "randomize per student" option because ' \
                       'the assessment is not randomizable' do
                    expect(activity).to have_no_randomize_option
                  end
                end

                step 'I see a tooltip with a complete summary' do
                  validate_activity_tooltip(activity_1_2_1)
                end
              end
            end

            step 'I see activity_1_2_2' do
              with_element(component.activity(2)) do |activity|
                expect(activity.checkbox).not_to be_checked

                step 'Even if this activity is only assigned in one section, ' \
                     'I see "varies" for the due date because the course has ' \
                     'the focus, not a section' do
                  expect(activity.due_date).to eq('varies')
                end

                step 'I see assignment details' do
                  step 'I see the availability details' do
                    expect(activity.availability).to eq('Yes')
                    expect(activity.availability_date).to eq(
                      format_date_time(
                        activity_1_2_2_assignment.show_at,
                        :compact_date_and_time,
                        section_1.time_zone
                      ).squish
                    )
                  end

                  step 'I see the result availability details' do
                    expect(activity.result_availability).to eq('Yes')
                    expect(activity.result_availability_date).to eq(
                      format_date_time(
                        activity_1_2_2_assignment.grades_available_at,
                        :compact_date_and_time,
                        section_1.time_zone
                      ).squish
                    )
                  end

                  step 'I see the assessment password protection' do
                    expect(activity.password_protected).to eq('No')
                  end

                  step 'I see the assessment time limit' do
                    expect(activity.time_limit).to start_with('None')
                  end

                  step 'I see unlimited number of attempts' do
                    expect(activity.attempts_number).to eq('Unlimited')
                  end

                  expect(activity.randomize).to eq('Yes')
                end

                step 'I see a tooltip with a complete summary' do
                  validate_activity_tooltip(activity_1_2_2)
                end
              end
            end
          end
        end
      end
    end

    purpose 'I can choose to see only assigned activities' do
      for_instructor_assessment_page do |pobject|
        pobject.show_only_assigned_activities

        purpose 'I see all assigned activities grouped by component' do
          step 'I see component 1 and component 2' do
            expect(pobject.components.map(&:title)).to eq(
              [component_1, component_2]
            )
          end

          step 'I see no assigned activity for component 1' do
            with_element(pobject.component(1)) do |component|
              expect(component.activities.map(&:title)).to be_empty
              expect(component).to have_nothing_assigned
            end
          end

          step 'I see all activities information for component 2' do
            with_element(pobject.component(2)) do |component|
              expect(component.activities.map(&:title)).to eq(
                [activity_1_2_1.title, activity_1_2_2.title]
              )
            end
          end
        end
      end
    end

    purpose 'I can select multiple activities to assign' do
      for_instructor_assessment_page do |pobject|
        pobject.show_all_activities

        purpose 'I can select activity by activity' do
          expect(pobject.assign_button).to be_disabled
          pobject.component(1).activity(1).checkbox.click
          expect(pobject.assign_button).to be_enabled
          pobject.component(1).activity(1).checkbox.click
          expect(pobject.assign_button).to be_disabled
        end

        purpose 'I can select all the activities of a component at once' do
          expect(pobject.assign_button).to be_disabled
          step 'Selecting one activity enables the assign button' do
            pobject.component(1).activity(1).checkbox.click
            expect(pobject.assign_button).to be_enabled
          end
          step 'I can select all the activities of a component' do
            pobject.component(2).select_all_activities
            expect(pobject.assign_button).to be_enabled
          end
          step 'I can unselect all the activities of a component' do
            pobject.component(1).unselect_all_activities
            expect(pobject.assign_button).to be_enabled
          end
          step 'The selected activities of the other component are still selected' do
            selected_activities = pobject.component(2).activities.map do |act|
              act.checkbox[:class].include?('show_check')
            end

            expect(selected_activities).to all(be_truthy)
            expect(pobject.assign_button).to be_enabled
          end
        end
      end
    end

    purpose 'I do not see the "randomize per student" option when assigning ' \
            'a non randomizable activity I do not see' do
      for_instructor_assessment_page do |pobject|

        # We have to unselect this, because all activities of the second component
        # are already assigned and we are testing here the assign modal, not the reassign one.
        step 'Make sure all activities are not selected' do
          pobject.component(1).unselect_all_activities
          pobject.component(2).unselect_all_activities
        end

        step 'Select an unasigned activity from the first component' do
          pobject.component(1).activity(1).checkbox.click
          pobject.assign_button.click
        end

        for_assignment_options_modal do |modal|
          expect(modal).to have_no_randomize_per_student_option
          modal.cancel_button.click
        end

        step 'Unselect the activity' do
          pobject.component(1).activity(1).checkbox.click
        end
      end
    end

    purpose 'I can assign multiple not assigned activities' do
      for_instructor_assessment_page do |pobject|
        pobject.component(1).activity(1).checkbox.click
        pobject.component(1).activity(2).checkbox.click
        pobject.assign_button.click

        purpose 'I can cancel the procedure at any time' do
          for_assignment_options_modal do |modal|
            modal.cancel_button.click
          end
        end

        pobject.assign_button.click

        for_assignment_options_modal do |modal|
          purpose 'A valid due date is required' do
            modal.due_date = '1234'
            modal.save_button.click
            wait_for_ajax
            expect(modal).to have_error('Due date must be a valid date.')
          end

          purpose 'The due date must be after the course start date' do
            modal.due_date = course.start_date - 2.days
            modal.save_button.click
            wait_for_ajax
            expect(modal).to have_error(
              "Due date must be after course start date, which is #{course.start_date}"
            )
          end

          purpose 'The due date must be before the course end date' do
            modal.due_date = course.end_date + 2.days
            modal.save_button.click
            wait_for_ajax
            expect(modal).to have_error(
              "Due date must be before course end date, which is #{course.end_date}"
            )
          end

          purpose 'Select a valid due date' do
            modal.due_date = valid_due_date
          end

          purpose 'I can choose the test availability' do
            purpose 'By default, the test will be hidden until I release it' do
              expect(modal.content_container).to have_selector(
                '[data-container="availability_text"]',
                text: 'The assessment will be hidden until'
              )
              expect(modal.content_container).to have_selector(
                '[data-container="availability_option"]',
                text: 'I release it.'
              )
            end

            purpose 'I can choose to keep the test hidden until a specific time' do
              modal.content_container.find(
                '[data-container="availability_option"] a'
              ).click
              modal.content_container.select(
                'a specific date and time',
                from: 'activity_assignment_show_assessment'
              )

              purpose 'A release date is required' do
                modal.save_button.click
                wait_for_ajax
                expect(modal).to have_error('Release date is required.')
              end

              purpose 'A valid release date is required' do
                modal.release_date = '1234'
                modal.save_button.click
                wait_for_ajax
                expect(modal).to have_error('You must specify a valid release date.')
              end

              purpose 'The release date must be before the due date' do
                modal.release_date = course.end_date
                modal.save_button.click
                wait_for_ajax
                expect(modal).to have_error('The assessment must be available before it is due.')
              end

              purpose 'Set a valid release date' do
                modal.release_date = valid_release_date
              end
            end
          end

          purpose 'I can choose when the results will be available' do
            purpose 'By default, results will be available when all students have been graded' do
              expect(modal.content_container).to have_selector(
                '[data-container="grade_availability_text"]',
                text: 'Results will be available'
              )
              expect(modal.content_container).to have_selector(
                '[data-container="grade_availability_option"]',
                text: 'when all students have been graded'
              )
            end

            purpose 'I can choose the make results available after a specific date and time' do
              modal.content_container.find(
                '[data-container="grade_availability_option"] a'
              ).click
              modal.content_container.select(
                'after a specific date and time',
                from: 'activity_assignment_grade_availability'
              )

              purpose 'A result availability date is required' do
                modal.save_button.click
                wait_for_ajax
                expect(modal).to have_error('Grade availability date is required.')
              end

              purpose 'A valid result availability date is required' do
                modal.result_availability_date = '1234'
                modal.save_button.click
                wait_for_ajax
                expect(modal).to have_error('You must specify a valid result availability date.')
              end

              purpose 'The result availability date must be after the release date' do
                modal.result_availability_date = valid_release_date - 2.days
                modal.save_button.click
                wait_for_ajax
                expect(modal).to have_error(
                  'Results for this assessment can only be made available after it is released.'
                )
              end

              purpose 'Set a valid result availability date' do
                modal.result_availability_date = valid_result_availability_date
              end
            end
          end

          purpose 'I can choose a time limit' do
            purpose 'By default, there is no time limit' do
              expect(modal.content_container).to have_selector(
                '[data-container="time_limit_text"]',
                text: 'Set a time limit (minutes)'
              )
            end

            # When setting a value lower than 15, a tooltip says
            # "value must be greater than or equal to 15."
            # When setting a value greater than 299, a tooltup says
            # "Value must be less than or equal to 299."
            # In both cases the out of range value is accepted when clicking on "save"
            # Either the verification must be removed or the assignment must be recused.
            purpose 'Set a valid time limit' do
              modal.content_container.find('[data-container="current_time_limit"] a').click
              modal.time_limit = 15
            end
          end

          purpose 'I can set a password' do
            purpose 'By default, there is no password' do
              expect(modal.content_container).to have_selector(
                '[data-container="password_text"]',
                text: 'Set a password'
              )
            end

            purpose 'The password must be less than 255 characters long' do
              long_password = '0123456789' * 30
              modal.password = long_password
              modal.save_button.click
              wait_for_ajax
              expect(modal).to have_error(
                'Password length must be less than 255.'
              )
            end

            purpose 'Set a valid password' do
              modal.password = '0123456789'
            end
          end

          purpose 'I can mark the assessments to be randomized' do
            modal.randomize_per_student = 'Yes'
          end

          step 'save the assignment' do
            modal.save_button.click
          end
        end
      end

      step 'I see a success message' do
        expect_flash_message(:notice, 'Activities assigned successfully.')
      end

      purpose 'The assignments have been saved into the database' do
        expect(
          Assignment.activity_assignments(
            [section_1.id, section_2.id], [activity_1_1_1]
          )
        ).to match_array(
          [
            have_attributes(
              due_date: valid_due_date,
              category_id: category.id,
              show_assessment: 'a specific date and time',
              show_at: valid_release_date.in_time_zone(section_1.time_zone),
              grade_availability: :on_specific_date,
              grades_available_at: valid_result_availability_date.in_time_zone(section_1.time_zone),
              randomize_per_student: true
            ),
            have_attributes(
              due_date: valid_due_date,
              category_id: category.id,
              show_assessment: 'a specific date and time',
              show_at: valid_release_date.in_time_zone(section_2.time_zone),
              grade_availability: :on_specific_date,
              grades_available_at: valid_result_availability_date.in_time_zone(section_2.time_zone),
              randomize_per_student: true
            )
          ]
        )
        expect(
          Assignment.activity_assignments(
            [section_1.id, section_2.id], [activity_1_1_2]
          )
        ).to match_array(
          [
            have_attributes(
              due_date: valid_due_date,
              category_id: category.id,
              show_assessment: 'a specific date and time',
              show_at: valid_release_date.in_time_zone(section_1.time_zone),
              grade_availability: :on_specific_date,
              grades_available_at: valid_result_availability_date.in_time_zone(section_1.time_zone),
              randomize_per_student: true
            ),
            have_attributes(
              due_date: valid_due_date,
              category_id: category.id,
              show_assessment: 'a specific date and time',
              show_at: valid_release_date.in_time_zone(section_2.time_zone),
              grade_availability: :on_specific_date,
              grades_available_at: valid_result_availability_date.in_time_zone(section_2.time_zone),
              randomize_per_student: true
            )
          ]
        )
      end

      step 'No activities are selected' do
        for_instructor_assessment_page.components.each do |component|
          component.activities.each do |activity|
            expect(activity.checkbox).not_to be_checked
          end
        end
      end

      step 'The assign button is disabled' do
        for_instructor_assessment_page do |pobject|
          expect(pobject.assign_button).to be_disabled
        end
      end

      purpose 'I see assignment details for the 2 activities I assigned' do
        with_element(for_instructor_assessment_page.component(1)) do |component|
          [component.activity(1), component.activity(2)].each do |activity|
            expect(activity.checkbox).not_to be_checked
            expect(activity.due_date).to eq(
              valid_due_date.strftime('%a %-m/%-d')
            )
            step 'I see assignment details' do
              step 'I see the availability details' do
                expect(activity.availability).to eq('No')
                step 'I see "varies" for the availability date because the 2 ' \
                     'assignments are in sections with different time zone' do
                  expect(activity.availability_date).to eq('Varies')
                end
              end

              step 'I see the result availability details' do
                expect(activity.result_availability).to eq('No')
                expect(activity.result_availability_date).to eq('Varies')
              end

              step 'I see the assessment password protection' do
                expect(activity.password_protected).to eq('Yes')
              end

              step 'I see the assessment time limit' do
                expect(activity.time_limit).to start_with('15 minutes')
              end

              step 'I see the number of attempts' do
                expect(activity.attempts_number).to eq('1')
              end
            end
          end

          purpose 'The activity that is not randomizable does not have the ' \
                  'randomize per student property' do
            expect(component.activity(1)).to have_no_randomize_option
          end

          purpose 'The activity that is randomizable has the randomize per ' \
                  'student property set' do
            expect(component.activity(2).randomize).to eq('Yes')
          end
        end
      end
    end

    purpose 'I change the focus to section 2' do
      focus_select_section(section_2)
    end

    purpose 'I see information for all assignments for section 2' do
      purpose 'I see all activities information for component 1' do
        with_element(for_instructor_assessment_page.component(1)) do |component|
          expect(component.activities.map(&:title)).to eq(
            [activity_1_1_1.title, activity_1_1_2.title]
          )

          [component.activity(1), component.activity(2)].each do |activity|
            expect(activity.checkbox).not_to be_checked
            step 'I see the due date' do
              expect(activity.due_date).to eq(
                valid_due_date.strftime('%a %-m/%-d')
              )
            end

            step 'I see assignment details' do
              step 'I see the availability details' do
                expect(activity.availability).to eq('No')
                expect(activity.availability_date).to eq(
                  format_date_time(
                    valid_release_date,
                    :compact_date_and_time,
                    section_2.time_zone
                  ).squish
                )
              end

              step 'I see the result availability details' do
                expect(activity.result_availability).to eq('No')
                expect(activity.result_availability_date).to eq(
                  format_date_time(
                    valid_result_availability_date,
                    :compact_date_and_time,
                    section_2.time_zone
                  ).squish
                )
              end

              step 'I see that the assignment is password protected' do
                expect(activity.password_protected).to eq('Yes')
              end

              step 'I see the assessment time limit' do
                expect(activity.time_limit).to start_with('15 minutes')
              end

              step 'I see the number of attempts' do
                expect(activity.attempts_number).to eq('1')
              end
            end
          end

          purpose 'Even if I assigned activity_1_1_1 with the "randomize per student" ' \
                  'option set, I do not see the "randomize per student" option ' \
                  'because this assessment does not support randomization' do
            expect(component.activity(1)).to have_no_randomize_option
          end

          purpose 'I see activity_1_1_2 will be randomized per student' do
            expect(component.activity(2).randomize).to eq('Yes')
          end
        end
      end

      purpose 'I see all activities information for component 2' do
        with_element(for_instructor_assessment_page.component(2)) do |component|
          expect(component.activities.map(&:title)).to eq(
            [activity_1_2_1.title, activity_1_2_2.title]
          )

          step 'I see activity_1_2_1' do
            with_element(component.activity(1)) do |activity|
              expect(activity.checkbox).not_to be_checked

              step 'I see the due date' do
                activity_1_2_1_assignment_2.due_date.strftime('%a %-m/%-d')
              end

              step 'I see assignment details' do
                step 'I see the availability details' do
                  expect(activity.availability).to eq('No')
                  expect(activity.availability_date).to eq('')
                end

                step 'I see the result availability details' do
                  expect(activity.result_availability).to eq('Yes')
                  expect(activity.result_availability_date).to eq('After grading')
                end

                step 'I see that the assignment is not password protected' do
                  expect(activity.password_protected).to eq('No')
                end

                step 'I see the assessment time limit' do
                  expect(activity.time_limit).to start_with('2 hours 30 minutes')
                end

                step 'I see the number of attempts' do
                  expect(activity.attempts_number).to eq(
                    activity_1_2_1_assignment_2.assigned_assessment_detail.number_of_attempts.to_s
                  )
                end

                step 'I do not see the "randomize per student" option because ' \
                     'the assessment is not randomizable' do
                  expect(activity).to have_no_randomize_option
                end
              end
            end
          end

          step 'I see activity_1_2_2' do
            with_element(component.activity(2)) do |activity|
              expect(activity.checkbox).not_to be_checked

              step 'I see no due date because this activity has no assignment ' \
                   'in section_2' do
                expect(activity.due_date).to eq('')
              end

              step 'I see no properties because this activity has no assignment ' \
                   'in section_2' do
                expect(activity).to have_no_properties
              end
            end
          end
        end
      end
    end

    purpose 'I can reassign activities' do
      for_instructor_assessment_page do |pobject|
        pobject.component(1).activity(2).checkbox.click
        pobject.component(2).activity(1).checkbox.click
        pobject.assign_button.click

        purpose 'I see a summary for each activity' do
          for_assignment_options_modal do |modal|
            with_element(modal.assignable_details(1)) do |assignable|
              expect(assignable.title).to eq(
                activity_1_2_1.strand_and_title_label
              )
              expect(assignable.category).to eq(category.name)
              expect(assignable.due_date.downcase).to eq(
                activity_1_2_1_assignment_2.due_date.strftime('%a %m/%d').downcase
              ).or eq('tomorrow')
            end

            with_element(modal.assignable_details(2)) do |assignable|
              expect(assignable.title).to eq(
                activity_1_1_2.strand_and_title_label
              )
              expect(assignable.category).to eq(category.name)
              expect(assignable.due_date).to eq(
                valid_due_date.strftime('%a %m/%d')
              )
            end
          end
        end

        purpose 'I can cancel the procedure at any time' do
          for_assignment_options_modal do |modal|
            modal.reassign_cancel_button.click
          end
        end

        pobject.assign_button.click

        purpose 'I confirm that I want to reassign the activities' do
          for_assignment_options_modal do |modal|
            modal.reassign_button.click
          end
        end

        for_assignment_options_modal do |modal|
          purpose 'A valid due date is required' do
            modal.due_date = '1234'
            modal.save_button.click
            wait_for_ajax
            expect(modal).to have_error('Due date must be a valid date.')
          end

          purpose 'The due date must be after the course start date' do
            modal.due_date = course.start_date - 2.days
            modal.save_button.click
            wait_for_ajax
            expect(modal).to have_error(
              "Due date must be after course start date, which is #{course.start_date}"
            )
          end

          purpose 'The due date must be before the course end date' do
            modal.due_date = course.end_date + 2.days
            modal.save_button.click
            wait_for_ajax
            expect(modal).to have_error(
              "Due date must be before course end date, which is #{course.end_date}"
            )
          end

          purpose 'Select a valid due date' do
            modal.due_date = valid_due_date
          end

          purpose 'I can choose the test availability' do
            purpose 'I can choose to make the results available after the due time' do
              modal.content_container.find(
                '[data-container="grade_availability_option"] a'
              ).click
              modal.content_container.select(
                'after the due time',
                from: 'activity_assignment_grade_availability'
              )
            end
          end

          purpose 'I can mark the assessments to be randomized' do
            modal.randomize_per_student = 'Yes'
          end

          step 'save the assignment' do
            modal.save_button.click
          end
        end
      end

      step 'I see a success message' do
        expect_flash_message(:notice, 'Activities assigned successfully.')
      end

      purpose 'The assignments have been saved into the database' do
        expect(
          Assignment.activity_assignments(
            [section_1.id, section_2.id], [activity_1_1_2]
          )
        ).to match_array(
          [
            have_attributes(
              section_id: section_1.id,
              due_date: valid_due_date,
              category_id: category.id,
              show_assessment: 'a specific date and time',
              show_at: valid_release_date.in_time_zone(section_1.time_zone),
              grade_availability: :on_specific_date,
              grades_available_at: valid_result_availability_date.in_time_zone(section_1.time_zone),
              randomize_per_student: true
            ),
            have_attributes(
              section_id: section_2.id,
              due_date: valid_due_date,
              category_id: category.id,
              show_assessment: 'I release it',
              show_at: nil,
              grade_availability: :on_due_date,
              grades_available_at: nil,
              randomize_per_student: true
            )
          ]
        )

        expect(
          Assignment.activity_assignments(
            [section_1.id, section_2.id], [activity_1_2_1]
          )
        ).to match_array(
          [
            # The assignment in section 1 should not have been updated
            activity_1_2_1_assignment_1,
            have_attributes(
              section_id: section_2.id,
              due_date: valid_due_date,
              category_id: category.id,
              show_assessment: 'I release it',
              show_at: nil,
              grade_availability: :on_due_date,
              grades_available_at: nil,
              randomize_per_student: true
            )
          ]
        )
      end
    end
  end

  describe 'Instructor assessment Google Classroom implementation' do
    context 'as an instructor browsing the assessment ToC having assessment' do
      let(:activity_gc) do
        create_assessment(
          title: 'activity gc',
          lesson: lesson_1
        )
      end

      before do
        create_assignment(
          activity_gc,
          section: section_1
        ).tap do |assignment|
          create_assigned_assessment(
            assignment
          )
        end
      end

      context 'when Google Classroom configuration is Enabled for school and Enabled for course' do
        let(:school) { create(:school, share_to_google_classroom: true) }
        let(:course) do
          create(
            :course,
            program: program,
            school: school,
            owner: instructor,
            share_to_google_classroom: true
          )
        end

        scenario 'Google Classroom button is visible on Instructor Assessment ToC' do
          visit instructor_assessments_path(
            program,
            display_lesson: activity_gc.lesson_id,
            toc_location: activity_gc.toc_location
          )
          step 'I see Google Classroom button on activity rows' do
            google_classroom_column_visible
            google_classroom_button_visible_in_all_activities
          end
        end
      end

      context 'when Google Classroom configuration is Disabled for school
        and Disabled for course' do
        let(:school) { create(:school, share_to_google_classroom: false) }
        let(:course) do
          create(
            :course,
            program: program,
            school: school,
            owner: instructor,
            share_to_google_classroom: false
          )
        end

        scenario 'Google Classroom button is not visible on Instructor Assessment ToC' do
          visit instructor_assessments_path(
            program,
            display_lesson: activity_gc.lesson_id,
            toc_location: activity_gc.toc_location
          )
          step 'I do not see Google Classroom button' do
            google_classroom_column_not_visible
            google_classroom_button_not_visible_in_all_activities
          end
        end
      end
    end
  end

  scenario 'As and instructor, my lesson and strand preference is stored ' \
           'if I navigate away from the content pages' do
    assessment_1_lesson_2 = nil
    step 'Setup the database' do
      step 'create concepts for lesson strands' do
        program.lessons.each do |lesson|
          lesson.toc_entries.each_with_index do |strand, index|
            create_concept_matching_strand_id(
              strand,
              name: strand.title,
              rank: index,
              assessment: true,
              lesson: lesson,
              program: program
            )
          end
        end
      end
      step 'Create activites in strand 2 for lesson 1' do
        create(
          :activity,
          lesson: lesson_1,
          toc_location: lesson_1.toc_entries[1].location,
          component_name: 'Quiz 1',
          concept: Concept.find(lesson_1.toc_entries[1].location)
        )
      end
      step 'Create activity in strand c for lesson 2' do
        assessment_1_lesson_2 = create(
          :activity,
          lesson: lesson_2,
          toc_location: lesson_2.toc_entries[2].location,
          component_name: 'Quiz 2',
          concept: Concept.find(lesson_2.toc_entries[2].location)
        )
      end
    end

    step 'Navigate to a lesson in the assessment ToC' do
      visit instructor_assessments_path(
        program,
        display_lesson: assessment_1_lesson_2.lesson_id,
        toc_location: assessment_1_lesson_2.toc_location
      )
    end

    step 'Navigate to a non content page' do
      visit instructor_program_resources_path(program)
    end

    purpose 'The ToC remembers what lesson and strand I was in' do
      visit instructor_assessments_path(program)
      expect(page).to have_selector(
        '.test-ls-dropdown-list-item.is-selected .test-ls-dropdown__list-item-text',
        text: lesson_2.name
      )
      expect(page).to have_selector(
        '#current_strand_name',
        text: lesson_2.toc_entries[2].title
      )
    end
  end
end
