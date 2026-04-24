feature 'Study Plan' do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:program) { create(:vol_program_with_toc_entries) }
  let(:course) { create(:course, program: program) }
  let(:section) { create(:section, course: course) }
  let(:student) { create(:student) }

  before do
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)
  end

  context 'with a Study Plan Practice Test activity type' do
    let(:activity_v1) { create_study_plan_practice_test_activity(program) }

    scenario 'student without an attempt should be redirected to the activity page' do
      visit section_study_plan_concepts_path(section, activity_v1)
      expect(page.current_url).not_to include 'study_plan'
      expect(page).to have_selector('.test-attempts-remaining')
    end

    context 'with a completed attempt' do
      scenario 'student should see a study plan v1' do
        create(
          :attempt_completed,
          user_id: student.id,
          activity_id: activity_v1.id,
          section_id: section.id
        )
        visit section_study_plan_concepts_path(section, activity_v1)
        expect(page).to have_selector('.test-study-plan-v1')
      end
    end
  end

  context 'with a Diagnostic V2 activity type' do
    let(:activity_v2) { create_summative_activity(program) }

    scenario 'student without an attempt should be redirected to the activity page' do
      visit section_study_plan_concepts_path(section, activity_v2)
      expect(page.current_url).not_to include 'study_plan'
      expect(page).to have_selector('.test-attempts-remaining')
    end

    context 'with a completed attempt' do
      scenario 'Student should see a study plan v2' do
        create(
          :attempt_completed,
          user_id: student.id,
          activity_id: activity_v2.id,
          section_id: section.id
        )
        visit section_study_plan_concepts_path(section, activity_v2)
        expect(page).to have_selector('.diagnostic_v2')
      end
    end
  end
end
