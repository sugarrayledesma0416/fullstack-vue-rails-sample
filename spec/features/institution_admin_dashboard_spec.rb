feature 'Institution admin dashboard', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers
  include Capybara::Angular::DSL

  def last_course_for_program(program)
    program.courses.last
  end

  def last_section_for_program(program)
    last_course_for_program(program).sections.last
  end

  let(:inst_admin) { create(:institution_admin) }
  let(:school) { create(:school, name: 'School 1') }
  let(:school_2) { create(:school, name: 'School 2') }
  let(:program) { create(:program_with_toc_entries, title: 'First Program') }
  let(:program_2) { create(:program, title: 'Second Program') }

  let!(:activities) do
    create_activities_with_the_same_toc_location(program, 5)
  end

  let!(:assessment) do
    # Pass an extra boolean arg to keep existing TOC entries in lesson.
    # This is to prevent the TOC entry for the regular activity from being overwritten.
    create_assessment_with_unit_lesson_concept(
      program,
      { lesson: activities[0].lesson },
      true
    )
  end

  let(:course) { create(:enterprise_course, program:, school:, owner: inst_admin) }
  let(:course_2) { create(:enterprise_course, program:, school:, owner: inst_admin) }
  let(:enterprise_section) { create(:enterprise_section, course:, instructor: inst_admin) }
  let(:enterprise_section_2) { create(:enterprise_section, course: course_2, instructor: inst_admin) }
  let(:section_2) { create(:section, course: course_2, instructor: inst_admin) }

  let!(:instructor) { create(:instructor) }
  let!(:other_instructor) { create(:instructor) }
  let!(:yet_another_instructor) { create(:instructor) }

  before do
    create(:program_config, program: program)
    create(
      :school_program_admin_user,
      user: inst_admin,
      school: school,
      program: program,
      account_type: inst_admin.account_type
    )
    create(
      :school_program_admin_user,
      user: inst_admin,
      school: school_2,
      program: program_2,
      account_type: inst_admin.account_type
    )
    create(
      :enterprise_section,
      course:,
      instructor: inst_admin
    )
    create(
      :enterprise_section,
      course: course_2,
      instructor: inst_admin
    )
    create(:school_user, school: school, user: inst_admin)
    stub_request(:get, /programs_cover_image_urls/).to_return(
      status: 200,
      body: {}.to_json
    )
    allow(Maestro::School).to receive(:instructors).and_return(
      'instructor_ids' => [
        instructor.id,
        other_instructor.id,
        yet_another_instructor.id
      ]
    )
    allow(Maestro::CourseLicense).to receive(:copy).and_return(true)
    allow(Maestro::CourseLicense).to receive(:create)
    allow(Maestro::CourseLicense).to receive(:all).and_return(
      [
        Maestro::CourseLicense.new(
          'license_group' => { 'id' => 1, 'demo' => false }
        )
      ]
    )

    allow(Maestro::CoursePackage).to receive(:all).and_return([])
    allow(Maestro::CoursePackage).to receive(:all_for_courses)
      .and_return({})

    allow(Maestro::CoursePackage).to receive(:all_for_course).and_return([])

    allow(Maestro::CoursePackage).to receive(:available_packages)
      .and_return([])
    initialize_program_access_client_calls_for_instructor(inst_admin, program)
    allow(InstitutionAdminDashboardPresenter).to receive(:open_courses)
      .and_return([course, course_2])
    allow(course).to receive(:enterprise_section).and_return(enterprise_section)
    allow(course_2).to receive(:enterprise_section).and_return(enterprise_section_2)
    allow(course_2).to receive(:sections).and_return([section_2])
    log_in_as(inst_admin)
  end

  scenario 'As an admin visiting the admin-dashboard page', js: true do
    # Visit the templates page
    # Use the UI to create templates
    # For one template, walk through the basic course/section functionality
    # Test that focus is correct
    # Test that template selection is preserved on return to templates page
    # Use the template(s) in the courses page
    purpose 'I can see the data for my school and related program on the dashboard' do
      step 'Visit the dashboard page' do
        visit institution_admin_dashboard_path
      end

      step 'Confirm that data for school and the related programs are displayed' do
        expect(page).to have_selector('.test-admin_school_dropdown', text: school.name)
        expect(page).to have_selector('.c-program-data__row', text: program.title)
      end
    end

    purpose 'I can select another school from the school dropdown' do
      step 'select another school from the dropdown' do
        within('.test-admin_school_dropdown') do
          find('.c-button-v3').hover
        end
        within('.test-admin_school_dropdown') do
          expect(page).to have_selector('.c-menu-v3__link-label', text: school.name)
          expect(page).to have_selector('.c-menu-v3__link-label', text: school_2.name)
        end
        within('.test-admin_school_dropdown') do
          click_on(school_2.name)
        end
      end

      step 'Confirm that data for selected school and the related programs are displayed' do
        expect(page).to have_selector('.test-admin_school_dropdown', text: school_2.name)
        expect(page).to have_selector('.c-program-data__row', text: program_2.title)
      end
    end

    purpose 'I see data for the first course on the list on page load' do
      step 'Click on program name' do
        visit institution_admin_dashboard_path
        click_on(program.title)
      end

      step 'Confirm that data for first course are displayed' do
        expect(page).to have_selector(".test-course-card-#{course.id}", text: course.name)
      end
    end

    purpose 'I can delete a course if it has no sections' do
      step 'Click to delete the course' do
        within(".test-course-card-#{course.id}") do
          find('.js-nav-system__link').hover
        end
        within(".test-course-card-#{course.id}") do
          expect(page).to have_selector('.test-delete-course-btn', text: 'Delete')
          find('.test-delete-course-btn').click
        end
        expect(page).to have_selector(".js-confirm-destroy-model-#{course.id}", visible: :visible)
        within(".test-course-card-#{course.id}") do
          find('.js-modal-confirm').click
        end
      end

      step 'Confirm that the course no longer appears in the list' do
        expect(page).not_to have_selector(".test-course-card-#{course.id}", text: course.name)
      end
    end

    purpose 'I can delete a section' do
      step 'Click the Manage button of the course to edit' do
        within(".test-course-card-#{course_2.id}") do
          click_on('Manage')
        end
      end

      step 'I can see the data of my sections' do
        expect(page).to have_selector(".test-section-#{section_2.id}-row", text: section_2.name)
      end

      step 'Click Delete button' do
        within(".test-section-#{section_2.id}-row") do
          find('.js-nav-system__link').hover
        end
        find(".test-delete-section-#{section_2.id}").click
        expect(page).to have_selector(".js-confirm-destroy-section-model-#{section_2.id}")
        within(".js-confirm-destroy-section-model-#{section_2.id}") do
          click_on('Delete')
        end
      end

      step 'Confirm that section is no longer in section list' do
        expect(page).not_to have_selector(".test-section-#{section_2.id}-row", text: section_2.name)
      end
    end

    purpose 'I can create a new section' do
      step 'Back to course list' do
        click_on('Back to Courses')
      end

      step 'Click the Manage button of a course' do
        within(".test-course-card-#{course_2.id}") do
          click_on('Manage')
        end
      end

      step 'Click the + Section button' do
        click_on('Section')
      end

      step 'Fill in the section creation form' do
        find('.js-create-section-name-field').click
        fill_in('section_name', with: 'Section 3')
        find('.js-create-section-submit').click
        find('.c-button-v3', text: 'Add Section').click
        click_button('Save')
      end

      step 'I can see the data of my new section' do
        expect(page).to have_selector(
          ".test-section-#{last_section_for_program(program).id}-row",
          text: 'Section 3'
        )
      end
    end

    xpurpose 'I can configure what courses to show on the courses page' do
      step 'Back to courses page' do
        click_on('Back to Courses')
      end

      step 'Click on "Configure View"' do
        click_on('Configure view')
      end

      step 'Confirm that courses are toggled as shown by default' do
        expect(page).to have_selector(".test-toggle-show-#{course_2.id}")
      end

      step 'Toggle one of the courses to hide it' do
        find("label[for=show_course_#{course_2.id}]").click
      end

      step 'Save changes' do
        click_on('Save Changes')
      end

      step 'Navigate to courses page' do
        click_on('Return to Courses')
      end

      step 'Confirm that the course to be hidden does not appear' do
        expect(page).not_to have_selector(".test-course-card-#{course_2.id}", text: course_2.name)
      end
    end
  end
end
