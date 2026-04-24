feature 'Rubric', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include Capybara::Angular::DSL
  include CapybaraViewHelpers
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }

  let(:course) do
    create(
      :course,
      owner: instructor,
      program: program,
      allows_help_requests: true,
      allows_review_requests: true
    )
  end

  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:rubric_activity) { create_solo_video_recording_activity_with_rubric(program) }
  let(:no_rubric_activity) { create_solo_video_recording_activity(program) }

  context 'with a student' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section: section, user: student)
    end

    scenario 'I can visit a static rubric for an activity with a rubric' do
      visit rubric_section_activity_path(section.id, rubric_activity)
      expect(page).to have_selector('.test-rubric-table')
    end

    scenario 'I see a flash message if there is no rubric' do
      visit rubric_section_activity_path(section.id, no_rubric_activity)
      expect_flash_message(:error, 'There is no rubric for this activity')
    end
  end
end
