feature 'Rubric activity', js: true, chrome: true, new_gb_sync: true do
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
  let(:rubric_activity) { create_composition_activity_with_rubric(program) }
  let(:rubric_type_no_rubric_activity) { create_solo_video_recording_activity(program) }

  context 'with a student' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      log_in_as(student)
      create(:active_enrollment, section: section, user: student)
    end

    scenario 'I can click on a rubric link when there is a rubric' do
      act_id = rubric_activity.id
      link = "a[href=\'/sections/#{section.id}/activities/#{act_id}/rubric?from=activity\']"
      visit section_activity_path(section.id, rubric_activity)
      expect(page).to have_css link
    end

    scenario 'I do not see a rubric link when there is no rubric' do
      visit section_activity_path(section.id, rubric_type_no_rubric_activity)
      expect(page).not_to have_selector('.test-rubric-link')
    end

    context 'with a completed, scored activity' do
      before do
        create(
          :attempt_completed,
          user: student,
          section: section,
          activity: rubric_activity,
          submission_id: 1
        )
      end

      scenario 'My score is linked to a rubric when rubric graded' do
        create(
          :gb_score_action,
          section_id: section.id,
          user_id: student.id,
          activity_id: rubric_activity.id,
          summation: {
            points_earned: 50,
            pending: false,
            points_possible: 100,
            submitted_at: Time.zone.now,
            rubric_graded: true
          }
        )
        visit section_activity_path(section.id, rubric_activity)
        expect(page).to have_selector('.test-scored-rubric-link')
      end

      scenario 'My score is not linked to a rubric when not rubric graded' do
        create(
          :gb_score_action,
          section_id: section.id,
          user_id: student.id,
          activity_id: rubric_activity.id,
          summation: {
            points_earned: 50,
            pending: false,
            points_possible: 100,
            submitted_at: Time.zone.now,
            rubric_graded: false
          }
        )
        visit section_activity_path(section.id, rubric_activity)
        expect(page).not_to have_selector('.test-scored-rubric-link')
      end
    end
  end
end
