feature 'Assistant instructor validation', test_debt: true do

  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:program) { create(:program_with_toc_entries, family: 'vista_online_learning') }
  let(:non_vol_program) { create(:program_with_toc_entries) }
  let(:owner) { create(:instructor) }
  let(:assistant) { create(:instructor) }

  class CourseMocker
    attr_accessor :owner, :program

    def initialize(owner, program, start_date=1.months.ago.to_date, end_date=6.months.from_now.to_date)
      self.owner = owner
      self.program = program
      @start_date = start_date
      @end_date = end_date
    end

    def course
      @course ||= create(:course, owner: owner, program: program, school: school, start_date: @start_date, end_date: @end_date)
    end

    def school
      @school ||= ( owner.schools.first || create(:school) )
    end

    def section
      @section ||= create(:section, course: course, instructor: owner)
    end

    def category
      @category ||= create(:category, course: course)
    end

    def add_assistant(assistant)
      create(:section_instructor, instructor: assistant, role: 'Assistant', section: section)
    end

    def create_activity
      create(:activity, lesson: first_lesson,
                         toc_location: toc_entry_for_activity.location,
                         toc_location_rank: 10)
    end

    def create_assessment
      create(:activity, lesson: first_lesson,
              toc_location: assessment_strand.location,
              concept: assessment_concept)
    end

    def assessment_strand
      return @assessment_strand if defined?(@assessment_strand)
      @assessment_strand = create(:toc_entry, assessment: true)
      first_lesson.toc_entries << @assessment_strand
      first_lesson.save!
      @assessment_strand
    end

    def assessment_concept
      @assessment_concept ||= create(:concept_for_quiz, program: program, lesson: first_lesson)
    end

    def toc_entry_for_activity
      # if we're in a program with substrand, we need the activity to be in a substrand
      # not in a strand, or it won't show up in the toc
      first_substrand || first_strand
    end
    private :toc_entry_for_activity

    def first_lesson
      program.units.first.lessons.first
    end
    private :first_lesson

    def first_strand
      first_lesson.toc_entries.first
    end
    private :first_strand

    def first_substrand
      if first_strand.children.present?
        first_strand.children.first
      end
    end
    private :first_substrand

  end

  context 'When course is not closed' do
    let(:course_mocker) { CourseMocker.new(owner, program) }
    let(:non_vol_course_mocker) { CourseMocker.new(owner, non_vol_program) }

    before do
      initialize_program_access_client_calls_for_instructor(assistant, program)
      course_mocker.add_assistant(assistant)
      non_vol_course_mocker.add_assistant(assistant)
      assistant.schools << course_mocker.school
      assistant.schools << non_vol_course_mocker.school
      log_in_as(assistant)
      #assistant.schools << course_mocker.school
    end

    scenario 'Assistant is allowed to create a new external activity from gradebook', :js => true do
      visit gradebook_category_path(program, course_mocker.category)
      find('a.add_column').click
      expect(page).to have_selector('h1.page_title', text: 'Add item')
    end

    scenario 'Assistant is allowed to add students to the section' do
      student = create(:student)
      allow(Maestro::Section).to receive(:prospective_students).and_return([student.id])
      visit new_instructor_enrollment_path(program)
      expect(page).to have_selector('h1.page_title', text: 'Add')
      expect(page).to have_selector('span.wizard_title', text: 'students')
      expect(page).to have_selector('span.course', text: "#{course_mocker.course.name}")
      expect(page).to have_selector('span.section', text: "#{course_mocker.section.name}")
    end

    scenario 'Assistant is allowed to drop students from the section' do
      visit gradebook_drop_students_edit_path(program)
      expect(page).to have_selector('h1.page_title', text: 'Drop students')
      expect(page).to have_selector('div#course', text: "#{course_mocker.course.name}")
    end

    scenario 'Assistant is allowed to create resources' do
      visit new_resource_path(program)
      expect(page).to have_selector('h1.page_title', text: 'Add')
      expect(page).to have_selector('label', text: "Title")
      expect(page).to have_selector('label', text: "Description")
    end

    scenario 'Assistant does not see checkboxes or controls for assigning and adding content from TOC', js: true do
      activity = course_mocker.create_activity
      category = course_mocker.category
      give_instructor_access_to_toc(activity: activity)

      visit instructor_toc_path(program)

      expect(page).not_to have_css('.toc_checkbox')
      expect(page).not_to have_css('.instructor-action-bar')
    end

    scenario 'Assistant does not see checkboxes or controls for assigning and adding content from Assessment', js: true do
      assessment = course_mocker.create_assessment
      category = course_mocker.category

      visit instructor_assessments_path(program, display_lesson: assessment.lesson_id)

      expect(page).not_to have_css('.toc_checkbox')
      expect(page).not_to have_css('.instructor-action-bar')
      expect(page).not_to have_css('.checkbox_all')
    end

    scenario  'Assistant is not allowed to edit course settings', :js => true do
      visit edit_instructor_course_path(program, course_mocker.course)
      expect(page).to have_selector('p', text: 'You must have Instructor access to view the requested page.')
    end

    scenario  'Assistant is not allowed to edit section settings', :js => true do
      visit edit_instructor_course_section_path(program, course_mocker.course, course_mocker.section)
      expect(page).to have_selector('p', text: 'You must have Instructor access to view the requested page.')
    end

    scenario 'Assistant sees "Start Assigning" grayed out and disabled in Calendar dropdown', js: true do
      activity = course_mocker.create_activity
      category = course_mocker.category
      give_instructor_access_to_toc(activity: activity)

      visit instructor_toc_path(program)

      expect(page).to have_css('.test-navigation-calendar-start-assigning', {text: 'Start Assigning'})
      expect(page).not_to have_link('Start Assigning', {href: instructor_new_assignments_path(program)})
    end

    scenario 'Assistant sees "start assigning" grayed out and disabled on Calendar page', js: true do
      activity = course_mocker.create_activity
      category = course_mocker.category
      give_instructor_access_to_toc(activity: activity)

      visit instructor_assignments_path(program)

      expect(page).to have_css('.test-instructor-assignments-start-assigning', {text: 'start assigning'})
      expect(page).not_to have_link('start assigning', {href: instructor_new_assignments_path(program)})
    end

    scenario 'Assistant does not see controls for reassigning or unassigning in the modal dialog in Assignment Calendar', js: true do
      # create an assignment
      create(:assignment, assignable: course_mocker.create_activity, section: course_mocker.section, category: course_mocker.category, due_date: Date.today)

      # visit the instructor assignment calendar view
      visit instructor_assignments_path(program)

      # click on an assignment due-date link to bring up the modal dialog
      find('.test-day-item').click

      # assert that we can't see the reassign, unassign and cancel text at the bottom of the dialog
      expect(page).not_to have_selector('#additional_links')
    end

    scenario 'Assistant sees options for deleting a section, editing a section, and assignment wizard grayed out and disabled in the section-edit-gear icon in Courses', js: true do
      # create another section so that assignment wizard can be enabled
      other_section = create(:section, course: course_mocker.course, instructor: owner)
      create(:section_instructor, instructor: assistant, role: 'Assistant', section: other_section)

      # visit the courses path
      visit instructor_dashboard_path(program)


      # click on the edit-section gear for a section in one of the courses
      first('.test-section-gear').click

      # assert that the Assignment Wizard, Edit Section and Delete Section links/buttons are all disabled
      assignment_wizard_path = instructor_assignment_wizard_index_path(program,
                                                     course_mocker.course,
                                                     section_id: course_mocker.section.id)
      edit_section_path = edit_instructor_course_section_path(program,
                                                              course_mocker.course,
                                                              course_mocker.section)
      expect(page).not_to have_link('Assignment Wizard', {href: assignment_wizard_path})
      expect(page).not_to have_link('Edit Section', {href: edit_section_path})
      expect(page).to have_css('.test-aw-asst-message')
      expect(page).to have_css('.test-edit-section-asst-message')
    end

    context 'When the assignment wizard is not enabled' do
      scenario 'assignment-wizard-assistant message supersedes need-another-course message', js: true do
        # create another section so that assignment wizard can be enabled
        other_section = create(:section, course: non_vol_course_mocker.course, instructor: owner)
        create(:section_instructor, instructor: assistant, role: 'Assistant', section: other_section)

        # log in
        initialize_program_access_client_calls_for_instructor(assistant, non_vol_program)
        log_in_as(assistant)
        # visit the courses path
        visit instructor_dashboard_path(non_vol_program)

        # click on the edit-section gear for a section in one of the courses
        first('.test-section-gear').click

        # assert that the help text for the assignment wizard is correct
        expect(page).to have_css('.test-aw-asst-message')
      end
    end

    scenario 'Assistant sees options for deleting a course and editing a course grayed out and disabled in the edit-course-gear icon in Courses', js: true do
      # visit the courses path
      visit instructor_dashboard_path(program)

      # click on the edit-course gear for the course
      find('.test-course-gear').click

      # assert that the Assignment Wizard, Edit Section and Delete Section links/buttons are all disabled
      edit_course_path = edit_instructor_course_path(program,
                                                     course_mocker.course)
      expect(page).not_to have_link('Edit Course', {href: edit_course_path})

      # assert that user sees correct error message
      expect(page).to have_css('.test-edit-course-asst-message')
    end

    scenario 'Assistant is redirected to the instructor dashboard path when accessing the start-assigning view', js: true do
      # visit the start-assigning view directly
      visit instructor_new_assignments_path(program)

      # assert that the redirect worked
      expect(URI.parse(page.current_url).path).to eq(instructor_dashboard_path(program))
    end
  end

  context 'When course is closed' do
    let(:due_date) { 24.months.ago.to_date }
    let(:older_start_date) { 28.months.ago.to_date }
    let(:course_mocker) { CourseMocker.new(owner, program, start_date=older_start_date, end_date=due_date) }

    before do
      initialize_program_access_client_calls_for_instructor(assistant, program)
      course_mocker.add_assistant(assistant)
      assistant.schools << course_mocker.school
      log_in_as(assistant)

      # visit the courses path
      visit instructor_dashboard_path(program)

      # click on the focus arrow
      find('.focus_indicator_arrow').click

      # click to see older courses
      find('.older_link').click

      find('#old_yearsSelectBoxItArrow').click
      find('a', text: due_date.year).click

      # click on the course name
      find("#js_course_#{course_mocker.course.id}").click
    end

    scenario 'User sees regular closed-course message for "Edit Course" if the course is closed', js:true do
      expect(page).to have_css('.test-edit-course-closed-course-message')
    end

    scenario 'Assistant sees assistant messaging for "Assignment Wizard" even if the section is closed', js:true do
      expect(page).to have_css('.test-aw-asst-message')
    end

    scenario 'User sees closed-section message for "Edit Section" if the section is closed', js:true do
      expect(page).to have_css('.test-edit-section-closed-section-message')
    end
  end
end
