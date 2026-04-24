feature 'Lti Instructor Dashboard', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:school) { create(:school) }
  let(:platform) { create(:lti_rostering_platform, school: school) }
  let(:instructor) { create(:lti_rostering_instructor) }
  let!(:lti_instructor_link) { create(:lti_user_link, user: instructor, lti_platform: platform) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course1) { create(:course, owner: instructor, program: program, school: school) }
  let!(:section1) { create(:section, course: course1, instructor: instructor, name: 'Course 1 Section') }
  let(:course2) { create(:course, owner: instructor, program: program, school: school) }
  let!(:section2) { create(:section, course: course2, instructor: instructor, name: 'Course 2 Section') }
  let!(:student) { create(:student) }

  let(:course_license) do
    Maestro::CourseLicense.new('license_group' => { 'id' => 1, 'demo' => false })
  end

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    allow(Maestro::CourseLicense).to receive(:all).and_return([course_license])
    allow(GradebookEngine::Section).to receive(:find).and_return(section2)
    log_in_as(instructor)
  end

  context 'when logged in as instructor' do
    scenario 'As an Lti instructor, I can be directed to my course dashboard' do
      purpose 'I should see the specified section in focus' do
        visit lti_instructor_dashboard_path(
          program_id: program.id,
          section_guid: section2.guid
        )
        expect(page).to have_selector(
          '#focus_indicator', text: "#{course2.name} #{section2.name}"
        )
      end

      purpose 'I cannot add a course or section' do
        expect(page).not_to have_selector('.test-add-course-link')
        expect(page).not_to have_selector('.test-add-section-link')
      end

      purpose 'I can edit my course' do
        expect(page).to have_selector(
          ".test-course-edit-link-#{course2.id}"
        )
      end

      purpose 'I can edit my section' do
        expect(page).to have_selector(
          ".test-section-edit-link-#{section2.id}"
        )
      end

      purpose 'I cannot control enrollments' do
        expect(page).not_to have_selector(
          'js-block-enrollment-section-link'
        )
      end

      purpose 'The instructions for students is disabled' do
        expect(page).to have_selector('.c-gear-del-link--disabled', text: 'Instructions for Students')
      end
    end
  end

  context 'when logged in as student' do
    before do
      initialize_program_access_client_calls_for_instructor(student, program)
      log_in_as(student)
    end

    scenario 'As a student, I cannot view the instructor dashboard' do
      purpose 'I cannot view the instructor dashboard' do
        step 'Try to go to the instructor Dashboard' do
          visit lti_instructor_dashboard_path(
            program_id: program.id,
            section_guid: section2.guid
          )
        end

        step 'I am redirected to the student Dashboard' do
          # TODO: expected behavior to be defined
          url = page.current_url
          expect(url).not_to include(
            lti_instructor_dashboard_path(
              program_id: program.id,
              section_guid: section2.guid
            )
          )
        end
      end
    end
  end
end
