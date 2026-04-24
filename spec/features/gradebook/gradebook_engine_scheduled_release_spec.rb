feature 'Scheduled Release for Gradebook',
  js:true, chrome: true, new_gb_sync: true do

  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:lesson) { program.units.first.lessons.first }
  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program,
      start_date: Date.new(2019, 7, 1)
    )
  end
  let!(:category) { create(:category, course: course) }
  let(:section) do
    create(
      :section,
      course: course,
      instructor: instructor,
      days_to_show_assignment_due_date: 4
    )
  end

  # Create three assignments:
  #   One assignment due in the past (should appear)
  #
  #   One assignment within the scheudled release window (should appear)
  #
  #   One assignment outside of the scheduled release window (should not appear)

  let(:past_due_activity) do
    create_activity_with_unit_lesson_and_concept(program, points_possible: 10)
  end

  let(:within_window_activity) do
    create_activity_with_unit_lesson_and_concept(program, points_possible: 10)
  end

  let(:outside_window_activity) do
    create_activity_with_unit_lesson_and_concept(program, points_possible: 10)
  end

  let!(:past_due_assignment) do
    create(:assignment, assignable: past_due_activity,
                        category: category,
                        due_date: 2.days.ago,
                        section: section)
  end

  let!(:within_window_assignment) do
    create(:assignment, assignable: within_window_activity,
                        category: category,
                        due_date: 2.days.from_now,
                        section: section)
  end

  let!(:outside_widnow_assignment) do
    create(:assignment, assignable: outside_window_activity,
                        category: category,
                        due_date: 7.days.from_now,
                        section: section)
  end

  before do
    create(:enrollment, user: student, section: section)
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)
  end

  scenario 'As a student navigating to the scores view' do
    visit gradebook_engine.course_section_scores_path(program_id: program.id,
                                                      course_id: course.id,
                                                      section_id: section.id)
    click_link('Grade')
    click_link('Scores')

    purpose 'I can see the released assignments in the Lesson view' do
      step 'I can see past due assignments' do
        expect(page).to have_selector(student_activity_grade_selector(student.id, past_due_activity.id))
      end

      step 'I can see assignments within scheduled release window' do
        expect(page).to have_selector(student_activity_grade_selector(student.id, within_window_activity.id))
      end

      step 'I cannot see assignments outside of the scheduled release window' do
        expect(page).not_to have_selector(student_activity_grade_selector(student.id, outside_window_activity.id))
      end
    end

    purpose 'I can see the released assignments in the Due Date view' do
      step 'Select Due Date from dropdown' do
        find('#lesson_or_due_date').find(:xpath, 'option[1]').select_option
      end

      step 'I can see past due assignments' do
        expect(page).to have_selector(student_activity_grade_selector(student.id, past_due_activity.id))
      end

      step 'I can see assignments within scheduled release window' do
        expect(page).to have_selector(student_activity_grade_selector(student.id, within_window_activity.id))
      end

      step 'I cannot see assignments outside of the scheduled release window' do
        # select the next week from the dropdown
        find('#all_lesson_or_week').find(:xpath, 'option[1]').select_option
        expect(page).not_to have_selector(student_activity_grade_selector(student.id, outside_window_activity.id))
      end
    end
  end
end
