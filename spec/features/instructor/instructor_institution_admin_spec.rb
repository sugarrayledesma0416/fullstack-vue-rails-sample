feature 'Instructor course from template setup', js: true, chrome: true, new_gb_sync: true, downloads: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include GradebookEngineHelpers
  include RspecJsDownloadHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:course_name) { 'May the course be with you' }
  let(:course_template_1_name) { 'course template 1' }
  let(:course_template_2_name) { 'course template 2' }
  let(:category_name_1) { 'Inquisitions' }
  let(:category_name_2) { 'Trials by Fire' }
  let(:section_template_1_name) { 'Section Template 1' }
  let(:section_template_2_name) { 'Section Template 2' }
  let(:other_section_template_name) { 'Other Section Template' }
  let(:section_name_1) { 'Section the First' }
  let(:section_name_2) { 'Section the Second' }
  let(:section_name_3) { 'Section the Third' }

  # Create two course templates.
  let!(:course_template_1) do
    create(:course_template,
           name: course_template_1_name,
           owner: instructor,
           program: program)
  end

  let!(:course_template_2) do
    create(:course_template,
           name: course_template_2_name,
           owner: instructor,
           program: program)
  end

  # Also create a regular course to make sure it's not selectable.
  let!(:non_template_course) { create(:course, program: program, owner: instructor) }

  # Provide categories for the course template that we'll select.
  let!(:category_template_1) do
    create(:category, course: course_template_1, name: category_name_1)
  end

  let!(:category_template_2) do
    create(:category, course: course_template_1, name: category_name_2)
  end

  # Create at least two sections for the course template that we'll select,
  #   and one that is in the other course template.
  let!(:section_template_1) do
    create(:section,
           course: course_template_1,
           name: section_template_1_name)
  end

  let!(:section_template_2) do
    create(:section,
           course: course_template_1,
           name: section_template_2_name)
  end

  let!(:other_section_template) do
    create(:section,
           course: course_template_2,
           name: other_section_template_name)
  end

  let!(:lesson) { create(:lesson) }
  let!(:concept) { create(:concept, lesson: lesson) }
  let!(:activity_1) { create(:activity, title: 'an activity', concept: concept, lesson: lesson) }
  let!(:assignment) do
    create(:assignment,
           section: section_template_1,
           category: category_template_1,
           assignable: activity_1,
           due_date: future_due_date)
  end

  let(:future_due_date) { Date.today + 2 }

  # TODO:
  # Create assignments for the sections.

  # We want to test that, when the course is created from the template,
  #   the categories are copied into new categories,
  #   the sections are copied to new sections for the created course,
  #   [TODO] and the assignments are copied into new assignments
  #          with the categories that map to the original template categories.

  xscenario 'Instructor course from template setup' do
    # Create stubs as needed to get through serialization of CourseOptions.
    allow(Maestro::CoursePackage).to receive(:all).and_return([])
    allow(Maestro::CoursePackage).to receive(:all_for_courses).and_return(
      # expected structure is a hash that maps the course GUID to
      #   an array of course packages (or, at any rate, an array).
      Hash.new { |h, k| h[k] = [] }
    )
    allow(Maestro::CoursePackage).to receive(:available_packages).and_return([])
    create(:vol_program_config, program: program)

    purpose 'Without dev access, I cannot visit the page for course-from-template setup' do
      step 'login as instructor' do
        initialize_program_access_client_calls_for_instructor(instructor, program)
        log_in_as(instructor)
      end

      step 'visit institution admin page' do
        # without dev access, this view should redirect to dashboard
        visit instructor_institution_admin_path(program)
        expect(page).to have_current_path(instructor_dashboard_path(program))
      end
    end

    purpose 'With dev access, I can visit the institution admin page' do
      step 'set dev cookie' do
        browser = Capybara.current_session.driver.browser
        browser.manage.add_cookie name: 'dev', value: '1'
      end

      step 'visit institution admin page' do
        # with dev access, we should have access to this view
        # for now, the view just has a control to add a course based on a template
        visit instructor_institution_admin_path(program)
        expect(page).to have_current_path(instructor_institution_admin_path(program))
      end

      step 'click to create course from template' do
        # we should see form to edit course name (will deal with owner later)
        # and a dropdown for templates.
        find('.test-create-course-from-template').click
        expect(page).to have_selector('.test-course-from-template-form', visible: true)
      end

      step 'name course and select a template' do
        # Fill in course name
        fill_in 'course_name', with: course_name

        # Assert contents of dropdown
        expect(page).to have_selector('option', text: course_template_1.name)
        expect(page).to have_selector('option', text: course_template_2.name)
        expect(page).not_to have_selector('option', text: non_template_course.name)

        # Select first course
        select(course_template_1.name, from: 'source_template')
        # TODO: Form should not be submittable at this point.
        #   It should be submittable only after we add at least one section.
      end

      step 'Choose how many sections to add' do
        # On selecting a number of sections, we should see that number of subforms
        #   for section information.
        select('3', from: 'section_count')

        expect(page).to have_selector('.test-section-from-template-form', count: 3)
      end

      step 'Fill in information for sections' do
        # TODO: Once section data is all filled in, form should be submittable.
        #   Anything that invalidates the form (e.g. blank section name) should disable submission.

        # Check one of the dropdowns for which section template names are present.
        # Assert that the section templates for the first course template
        #   are in the dropdown.
        # Assert that the section template for the other course template
        #   is not in the dropdown.
        expect(page).to have_selector('option', text: section_template_1_name)
        expect(page).to have_selector('option', text: section_template_2_name)
        expect(page).not_to have_selector('option', text: other_section_template_name)

        # Base the first two sections on section template 1,
        #   and the third on section template 2.
        select('Section Template 1', from: 'source_section_template_0')
        fill_in 'section_name_0', with: section_name_1
        select('Section Template 1', from: 'source_section_template_1')
        fill_in 'section_name_1', with: section_name_2
        select('Section Template 2', from: 'source_section_template_2')
        fill_in 'section_name_2', with: section_name_3
      end

      step 'Submit form to save course and sections' do
        # Click on submit
        find('.js-submit-form').click

        # Confirm that we remain on the admin page
        expect(page).to have_current_path(instructor_institution_admin_path(program),
                                          only_path: true)
      end

      step 'Visit instructor dashboard to confirm that course and sections are present' do
        # Visit dashboard
        visit instructor_dashboard_path(program)

        # Check that new course is listed
        expect(page).to have_selector('a', text: course_name)
        expect(page).to have_selector('a', text: section_name_1)
        expect(page).to have_selector('a', text: section_name_2)
        expect(page).to have_selector('a', text: section_name_3)

        # Check that the two sections created from section template 1 show the one assignment's
        #   due date as the next due date
        expect(page).to have_selector('div.duedate', text: future_due_date.strftime('%b %d'), count: 2)
      end

      step 'In edit-course view, check that categories were copied successfully' do
        # Click on course gear -> "edit course"
        find(".test-course-gear-#{Course.last.id}").click
        find(".test-course-edit-link-#{Course.last.id}").click

        # Confirm that edit view shows for the right course
        expect(page).to have_selector('h3', text: course_name)

        # Click on the "gradebook" tab
        click_on('Gradebook')

        # Assert that expected categories are shown on page
        expect(page).to have_selector('a', text: category_name_1)
        expect(page).to have_selector('a', text: category_name_2)
      end
    end
  end
end
