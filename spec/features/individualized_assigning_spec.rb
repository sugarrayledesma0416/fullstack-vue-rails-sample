feature 'Individualized Assigning', chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include CapybaraViewHelpers
  include GradebookEngineHelpers
  include InstructorGradingHelpers

  def create_auto_graded_activity
    create_activity_with_content(
      auto_graded_fixture,
      program,
      grading_method: 'auto',
      lesson: lesson,
      strand_id: non_assessment_strand.location
    )
  end

  def create_instructor_graded_activity
    create_activity_with_content(
      instructor_graded_fixture,
      program,
      grading_method: 'instructor',
      lesson: lesson,
      strand_id: non_assessment_strand.location
    )
  end

  def expect_correct_non_assessment_workset
    workset_activity_list = find_all('.test-assignment-group li')
    expect(workset_activity_list.size).to eq(2)
    expect(page).to have_selector(
      '.test-current-activity-title',
      text: activity_2.title
    )
  end

  def expect_correct_multi_due_date_non_assessment_workset
    workset_activity_list = find_all('.test-assignment-group li')
    expect(workset_activity_list.size).to eq(3)
    expect(page).to have_selector(
      '.test-current-activity-title',
      text: activity_1.title
    )
  end

  def assessment_labels(selector)
    page.find_all(selector).map(&:text)
  end

  def student_checkbox(activity, user)
    page.find(
      "input[type=checkbox][name='activity_#{activity.id}[user_#{user.id}][assigned]']"
    )
  end

  def select_activity_to_be_assigned(activity)
    checkbox = "#activity_#{activity.id}_checkbox"
    find(checkbox).click
  end

  def click_assign_activities_button
    find('.instructor-action-button').click
  end

  def individually_assign_dropdown
    find('#activity_assignment_individually_assignable')
  end

  def fill_in_due_date(date)
    due_date_field = find('#activity_assignment_due_date')
    due_date_field.click
    due_date_field.set date.strftime('%m/%d/%Y')
  end

  def click_assignment_modal_save_button
    page.all('.link_savechanges button')[1].click
  end

  def assignment_for(activity)
    Assignment.find_by(assignable_id: activity.id, section_id: section.id)
  end

  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program, rank: 1) }
  let(:non_assessment_strand) { create(:toc_entry) }
  let(:future_due_date) { 2.days.from_now.to_date }

  let!(:lesson) do
    create(:lesson, toc_entries: [non_assessment_strand], unit: unit)
  end

  let(:course) { create(:course, owner: instructor, program: program) }
  let(:category) do
    create(:category, course: course, penalty_percent: 0, weighting_percent: 100)
  end
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:course_licenses) { [] }

  let(:quiz_strand) { create(:assessment_toc_entry, title: 'Quizzes') }
  let(:quiz_concept) do
    create(
      :concept,
      assessment: true,
      id: quiz_strand.location,
      lesson: lesson,
      name: 'Quiz'
    )
  end

  let(:test_strand) { create(:assessment_toc_entry, title: 'Tests') }
  let(:test_concept) do
    create(
      :concept,
      assessment: true,
      id: test_strand.location,
      lesson: lesson,
      name: 'Test'
    )
  end

  let(:exam_strand) { create(:assessment_toc_entry, title: 'Exams') }
  let(:exam_concept) do
    create(
      :concept,
      assessment: true,
      id: exam_strand.location,
      lesson: lesson,
      name: 'Exam'
    )
  end

  let(:auto_graded_fixture) do
    File.join('spec', 'fixtures', 'xml', 'multiple_choice.xml')
  end

  let(:instructor_graded_fixture) do
    File.join('spec', 'fixtures', 'xml', 'open_ended.xml')
  end

  let(:individual_assign_menu_label) { 'Individual Assigning' }

  let!(:activity_1) { create_auto_graded_activity }
  let!(:activity_2) { create_auto_graded_activity }
  let!(:activity_3) { create_auto_graded_activity }

  describe 'As an instructor' do
    before do
      initialize_program_access_client_calls_for_instructor(instructor, program)
      course_licenses << Maestro::CourseLicense.new('license_group' => { 'id' => 1, 'demo' => false })
      allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)
      instructor.schools << section.course.school
      log_in_as(instructor)
    end

    scenario 'I see individual assignments for students reflected in ' \
             'the gradebook' do
      purpose 'The Individual Assigning menu item is disabled if I have no ' \
              'courses' do
        visit instructor_dashboard_path(program)
        page.find('#focus_indicator').click
        within('#focus_menu_container') { click_link(section.name) }

        within('#main-menubar') do
          expect(page).to have_selector(
            'span.disabled', text: individual_assign_menu_label
          )
        end
      end

      step 'Create category, which causes course creation' do
        category
      end

      step 'Create enrollments, which cause creation of sections' do
        create(:active_enrollment, section: section, user: student_1)
        create(:active_enrollment, section: section, user: student_2)
      end

      purpose 'The Individual Assigning menu item is disabled if I have ' \
              'open courses that do not allow it' do
        visit instructor_dashboard_path(program)

        within('#main-menubar') do
          expect(page).to have_selector(
            'span.disabled', text: individual_assign_menu_label
          )
        end
      end

      purpose 'I should not see a dropdown for individualized assigning if ' \
              'my course does not allow it' do
        visit instructor_toc_path(program)
        select_activity_to_be_assigned(activity_1)
        click_assign_activities_button
        expect(page).to have_no_selector('.js-individual-assign-dropdown')
      end

      course.update!(allow_individual_assign: true)

      purpose 'The Individual Assigning menu item is not disabled if I have ' \
              'open courses that allow it' do
        visit instructor_dashboard_path(program)

        within('#main-menubar') do
          expect(page).to have_no_selector(
            'span.disabled', text: individual_assign_menu_label
          )
          menu_item = page.find('a', text: individual_assign_menu_label)
          expect(menu_item[:class]).not_to include('disabled')
        end
      end

      purpose 'I should see a dropdown for individualized assigning if my ' \
              'course allows it' do
        visit instructor_toc_path(program)
        select_activity_to_be_assigned(activity_1)
        click_assign_activities_button
        expect(page).to have_selector('.js-individual-assign-dropdown')
      end

      fill_in_due_date(1.day.ago)

      select('Individual Students', from: 'Assign to')

      click_assignment_modal_save_button

      step 'I see the flash message "Activities assigned successfully."' do
        expect_flash_message(:notice, 'Activity assigned successfully.')
      end

      purpose 'The assignment should be individually assignable' do
        expect(assignment_for(activity_1)).to be_individually_assignable
      end

      purpose 'I can assign the individually-assignable assignment to ' \
              'specific students' do
        visit instructor_individual_assignments_path(program_id: program.id)

        expect(page).to have_selector(
          '.test-activity-column-activity-title',
          text: activity_1.title
        )

        student_checkbox(activity_1, student_1).check

        click_button('Save Changes')

        expect(student_checkbox(activity_1, student_1)).to be_checked

        step 'Verify student 1 has an individual assignment' do
          expect(
            IndividualAssignment.where(
              activity_id: activity_1.id, section_id: section.id, user_id: student_1.id
            )
          ).to exist
        end

        step 'Verify student 2 does not have an individual assignment' do
          expect(
            IndividualAssignment.where(
              activity_id: activity_1.id, section_id: section.id, user_id: student_2.id
            )
          ).not_to exist
        end
      end

      # TODO: On gradebook grid view,
      #       - Student 1 grade should show 0%
      #       - Student 2 grade should show --
      #       Will need to add some test-classes on the student rows in order
      #       to target the correct grid cells for this.
      # visit(
      #   gradebook_engine.course_section_scores_path(
      #     course_id: course.id, program_id: program.id, section_id: section.id
      #   )
      # )

      purpose 'I should see the individually assigned assignment counted as ' \
              'assigned on the single student overview view for student 1' do
        visit(
          gradebook_engine.section_user_overview_path(
            program_id: program.id, section_id: section.id, user_id: student_1.id
          )
        )

        expect(page).to have_selector('.test-assigned-count', text: 1)
      end

      activity_1_label = "#{activity_1.concept.name}: #{activity_1.title}"

      purpose 'I should see the individually assigned assignment listed as ' \
              'assigned on the single student scores view for student 1' do
        visit(
          gradebook_engine.section_user_scores_path(
            program_id: program.id, section_id: section.id, user_id: student_1.id
          )
        )

        expect(page).to have_selector('a', text: activity_1_label)
      end

      purpose 'I should not see the individually assigned assignment counted ' \
              'as assigned on the single student overview view for student 2' do
        visit(
          gradebook_engine.section_user_overview_path(
            program_id: program.id, section_id: section.id, user_id: student_2.id
          )
        )

        expect(page).to have_selector('.test-assigned-count', text: 0)
      end

      purpose 'I should not see the individually assigned assignment listed ' \
              'as assigned on the single student overview view for student 2' do
        visit(
          gradebook_engine.section_user_scores_path(
            program_id: program.id, section_id: section.id, user_id: student_2.id
          )
        )

        expect(page).to have_no_selector('a', text: activity_1_label)
        expect(page).to have_text('There are no assignments')
      end

      purpose 'I should see the individually assigned assignment listed ' \
              'on the single student unassigned work view for student 2' do
        create_gradebook_engine_submission(
          activity: activity_1,
          student: student_2,
          pending: false,
          points_earned: activity_1.points_possible,
          submitted_at: 2.days.ago
        )

        visit(
          gradebook_engine.section_user_student_unassigned_work_path(
            program_id: program.id, section_id: section.id, user_id: student_2.id
          )
        )

        expect(page).to have_selector('a', text: activity_1_label)
        expect(page).to have_selector('a', text: '100.0%')
      end

      step 'Assign an activity to not be individually assignable' do
        visit instructor_toc_path(program)
        select_activity_to_be_assigned(activity_2)
        click_assign_activities_button
        fill_in_due_date(1.day.ago)
        select('Entire Section', from: 'Assign to')
        click_assignment_modal_save_button
      end

      step 'I see the flash message "Activities assigned successfully."' do
        expect_flash_message(:notice, 'Activity assigned successfully.')
      end

      visit instructor_individual_assignments_path(program_id: program.id)

      expect(page).to have_selector(
        '.test-activity-column-activity-title',
        text: activity_1.title
      )

      expect(page).to have_no_selector(
        '.test-activity-column-activity-title',
        text: activity_2.title
      )

      find('label', text: 'Individually Assigned Only').click

      expect(page).to have_selector(
        '.test-activity-column-activity-title',
        text: activity_2.title
      )

      Assignment.find_by(assignable_id: activity_2.id).destroy

      purpose 'I cannot change the individually-assignable status of multiple ' \
              'activities when some are individually-assignable and others are ' \
              'not assigned at all' do
        visit instructor_toc_path(program)

        # Already set to individually-assignable
        select_activity_to_be_assigned(activity_1)

        # Not assigned
        select_activity_to_be_assigned(activity_2)

        click_assign_activities_button

        click_button('reassign')

        expect(individually_assign_dropdown).to be_disabled

        fill_in_due_date(1.day.ago)
        click_assignment_modal_save_button
        wait_for_ajax

        purpose 'The assignment that was individually assignable should ' \
                'still be individually assignable' do
          expect(assignment_for(activity_1)).to be_individually_assignable
        end

        purpose 'The newly assigned assignment should not be individually ' \
                'assignable' do
          expect(assignment_for(activity_2)).not_to be_individually_assignable
        end
      end

      purpose 'I cannot change the individually-assignable status of multiple ' \
              'activities when some are individually-assignable and others are ' \
              'assigned but not individually-assignable' do
        # Already set to individually-assignable
        select_activity_to_be_assigned(activity_1)

        # Assigned but not individually-assignable
        select_activity_to_be_assigned(activity_2)

        click_assign_activities_button
        wait_for_ajax

        click_button('reassign')

        expect(individually_assign_dropdown).to be_disabled

        fill_in_due_date(1.day.ago)
        click_assignment_modal_save_button
        wait_for_ajax

        purpose 'The assignment that was individually-assignable should ' \
                'still be individually-assignable' do
          expect(assignment_for(activity_1)).to be_individually_assignable
        end

        purpose 'The assignment that was not individually-assignable should' \
                'still not be individually-assignable' do
          expect(assignment_for(activity_2)).not_to be_individually_assignable
        end
      end

      purpose 'I can change the individually-assignable status of multiple ' \
              'activities when some are assigned but are not ' \
              'individually-assignable and others are unassigned' do
        # Assigned but not individually-assignable
        select_activity_to_be_assigned(activity_2)

        # Not assigned
        select_activity_to_be_assigned(activity_3)

        click_assign_activities_button

        click_button('reassign')

        expect(individually_assign_dropdown).not_to be_disabled
        expect(individually_assign_dropdown.value).to eq('false')

        fill_in_due_date(1.day.ago)
        select('Individual Students', from: 'Assign to')

        click_assignment_modal_save_button
        wait_for_ajax

        purpose 'Both assignment should be individually-assignable' do
          expect(assignment_for(activity_2)).to be_individually_assignable
          expect(assignment_for(activity_3)).to be_individually_assignable
        end
      end

      purpose 'I can change the individually-assignable status of multiple ' \
              'activities when they are all individually-assignable' do
        # Already set to individually-assignable
        select_activity_to_be_assigned(activity_1)
        select_activity_to_be_assigned(activity_2)

        click_assign_activities_button

        click_button('reassign')

        expect(individually_assign_dropdown).not_to be_disabled
        expect(individually_assign_dropdown.value).to eq('true')

        fill_in_due_date(1.day.ago)
        select('Entire Section', from: 'Assign to')
        click_assignment_modal_save_button
        wait_for_ajax

        purpose 'Both assignment should not be individually-assignable' do
          expect(assignment_for(activity_1)).not_to be_individually_assignable
          expect(assignment_for(activity_2)).not_to be_individually_assignable
        end
      end

      purpose 'I can change the individually-assignable status of multiple ' \
              'activities when none of them are individually-assignable' do
        # Already set to not individually-assignable
        select_activity_to_be_assigned(activity_1)
        select_activity_to_be_assigned(activity_2)

        click_assign_activities_button

        click_button('reassign')

        expect(individually_assign_dropdown).not_to be_disabled
        expect(individually_assign_dropdown.value).to eq('false')

        fill_in_due_date(1.day.ago)
        select('Individual Students', from: 'Assign to')
        click_assignment_modal_save_button
        wait_for_ajax

        purpose 'Both assignment should be individually-assignable' do
          expect(assignment_for(activity_1)).to be_individually_assignable
          expect(assignment_for(activity_2)).to be_individually_assignable
        end
      end
    end

    scenario 'I see individual assignments for students without custom ' \
             'due dates reflected in grading sets' do
      step 'Create enrollments, which cause creation of sections' do
        create(:active_enrollment, section:, user: student_1)
        create(:active_enrollment, section:, user: student_2)
      end

      ig_activity = create_instructor_graded_activity

      results = blank_open_ended_results(ig_activity)
      allow_any_instance_of(Attempt).to receive(:results).and_return(results)

      create(
        :assignment,
        assignable: ig_activity,
        category:,
        due_date: 2.days.ago,
        individually_assignable: true,
        section:
      )

      purpose 'I see activities that are individually-assignable and have ' \
              'been submitted by students to whom they were not assigned ' \
              'in the unassigned activities section' do
        create(
          :attempt_completed,
          activity: ig_activity,
          section:,
          user: student_1
        )

        create_gradebook_engine_submission(
          activity: ig_activity,
          pending: true,
          section:,
          student: student_1,
          submitted_at: 3.days.ago,
          time_spent: 1
        )

        visit instructor_grading_tasks_assignments_path(program.id)

        for_instructor_grading_tasks_assignments_page do |pobject|
          expect(pobject.needs_grading_section_count).to eq('0')

          expect(pobject.unassigned_activities_section_count).to eq('1')

          click_link('Unassigned activities')
          expect_grading_list_item(activity: ig_activity, count: 1)
        end
      end

      purpose 'Submissions for students to whom an individually-assignable ' \
              'assignment have not been assigned do not show up in the ' \
              'grading set' do
        create(
          :attempt_completed,
          activity: ig_activity,
          section:,
          user: student_2
        )

        create_gradebook_engine_submission(
          activity: ig_activity,
          pending: true,
          section:,
          student: student_2,
          submitted_at: 3.days.ago,
          time_spent: 1
        )

        IndividualAssignment.create!(
          activity_id: ig_activity.id,
          section_id: section.id,
          user_id: student_2.id
        )

        visit instructor_grading_tasks_assignments_path(program.id)

        for_instructor_grading_tasks_assignments_page do |pobject|
          expect(pobject.needs_grading_section_count).to eq('1')
          expect_grading_list_item(activity: ig_activity, count: 1)

          expect(page).to have_selector(
            '.test-submitted-number',
            text: '1 of 1 submitted'
          )

          pobject.grading_list_item(ig_activity).click
        end

        choose('Spotcheck Student Work')
        click_on('start grading')

        expect(page).to have_selector('#random_student_table')

        student_names = all('#random_student_table .students .names').map(&:text)
        expect(student_names).to contain_exactly(student_2.last_name_first)

        visit instructor_grading_tasks_assignments_path(program.id)

        for_instructor_grading_tasks_assignments_page do |pobject|
          pobject.grading_list_item(ig_activity).click
        end

        choose('Question by question')
        click_on('start grading')

        expect(page).to have_text(student_2.full_name)
        expect(page).to have_no_text(student_1.full_name)
      end

      purpose 'Submissions for students to whom an individually-assignable ' \
              'assignment have been assigned do not show up in an unassigned ' \
              'work grading set' do
        visit instructor_grading_tasks_assignments_path(program.id)
        click_link('Unassigned activities')

        for_instructor_grading_tasks_assignments_page do |pobject|
          within('#unassigned_activities_section') do
            expect_grading_list_item(activity: ig_activity, count: 1)
            pobject.grading_list_item(ig_activity).click
          end
        end

        choose('Spotcheck Student Work')
        click_on('start grading')

        student_names = all('#random_student_table .students .names').map(&:text)
        expect(student_names).to contain_exactly(student_1.last_name_first)

        visit instructor_grading_tasks_assignments_path(program.id)
        click_link('Unassigned activities')

        for_instructor_grading_tasks_assignments_page do |pobject|
          within('#unassigned_activities_section') do
            expect_grading_list_item(activity: ig_activity, count: 1)
            pobject.grading_list_item(ig_activity).click
          end
        end

        choose('Question by question')
        click_on('start grading')

        expect(page).to have_text(student_1.full_name)
        expect(page).to have_no_text(student_2.full_name)
      end

      purpose 'I see activities that are individually-assignable and have ' \
              'been submitted by students to whom they were assigned ' \
              'in the needs grading section' do
        IndividualAssignment.create!(
          activity_id: ig_activity.id,
          section_id: section.id,
          user_id: student_1.id
        )

        visit instructor_grading_tasks_assignments_path(program.id)

        for_instructor_grading_tasks_assignments_page do |pobject|
          expect(pobject.needs_grading_section_count).to eq('1')
          expect_grading_list_item(activity: ig_activity, count: 2)

          expect(pobject.unassigned_activities_section_count).to eq('0')
        end
      end
    end

    scenario 'I see individual assignments for students with custom ' \
             'due dates reflected in grading sets' do
      step 'Create enrollments, which cause creation of sections' do
        create(:active_enrollment, section:, user: student_1)
        create(:active_enrollment, section:, user: student_2)
      end

      ig_activity = create_instructor_graded_activity

      results = blank_open_ended_results(ig_activity)
      allow_any_instance_of(Attempt).to receive(:results).and_return(results)

      ig_assignment = create(
        :assignment,
        assignable: ig_activity,
        category:,
        due_date: 2.days.from_now.to_date,
        individually_assignable: true,
        section:
      )

      purpose 'I see activities that are individually-assignable and have ' \
              'been submitted by students to whom they were assigned with a ' \
              'custom due date in the past in the needs grading section' do
        IndividualAssignment.create!(
          activity_id: ig_activity.id,
          due_date: 3.days.ago.to_date,
          section_id: section.id,
          user_id: student_1.id
        )

        create(
          :attempt_completed,
          activity: ig_activity,
          section:,
          user: student_1
        )

        create_gradebook_engine_submission(
          activity: ig_activity,
          pending: true,
          section:,
          student: student_1,
          submitted_at: 3.days.ago,
          time_spent: 1
        )

        IndividualAssignment.create!(
          activity_id: ig_activity.id,
          due_date: 3.days.from_now.to_date,
          section_id: section.id,
          user_id: student_2.id
        )

        create(
          :attempt_completed,
          activity: ig_activity,
          section:,
          user: student_2
        )

        create_gradebook_engine_submission(
          activity: ig_activity,
          pending: true,
          section:,
          student: student_2,
          submitted_at: 3.days.ago,
          time_spent: 1
        )

        visit instructor_grading_tasks_assignments_path(program.id)

        for_instructor_grading_tasks_assignments_page do |pobject|
          expect(pobject.needs_grading_section_count).to eq('1')

          expect_grading_list_item(activity: ig_activity, count: 1)

          expect(pobject.upcoming_grading_section_count).to eq('1')

          expect(page).to have_selector(
            '.test-submitted-number',
            text: '2 of 2 submitted'
          )
        end
      end

      # purpose 'Submissions for students to whom an individually-assignable ' \
      #         'assignment has been assigned with a custom due date in the ' \
      #         'future do not show up in the needs-grading grading set' do
      #   for_instructor_grading_tasks_assignments_page do |pobject|
      #     puts(pobject.grading_list_item(ig_activity)).inspect
      #
      #     pobject.grading_list_item(ig_activity).click
      #   end
      #
      #   choose('Spotcheck Student Work')
      #   click_on('start grading')
      #
      #   expect(page).to have_selector('#random_student_table')
      #
      #   student_names = all('#random_student_table .students .names').map(&:text)
      #   expect(student_names).to contain_exactly(student_2.last_name_first)
      #
      #   visit instructor_grading_tasks_assignments_path(program.id)
      #
      #   for_instructor_grading_tasks_assignments_page do |pobject|
      #     pobject.grading_list_item(ig_activity).click
      #   end
      #
      #   choose('Question by question')
      #   click_on('start grading')
      #
      #   expect(page).to have_text(student_2.full_name)
      #   expect(page).to have_no_text(student_1.full_name)
      # end

      purpose 'I see activities that are individually-assignable and have ' \
              'been submitted by students to whom they were assigned with a ' \
              'custom due date in the future in the upcoming grading section' do
        ig_assignment.update!(due_date: 2.days.ago.to_date)

        visit instructor_grading_tasks_assignments_path(program.id)

        for_instructor_grading_tasks_assignments_page do |pobject|
          expect(pobject.upcoming_grading_section_count).to eq('1')
          expect_grading_list_item(activity: ig_activity, count: 1)

          expect(pobject.unassigned_activities_section_count).to eq('0')
        end
      end
    end
  end

  scenario 'As a student, my dashboard views and worksets reflect my ' \
           'individual assignments without multiple due dates' do
    create(:active_enrollment, section: section, user: student_1)
    initialize_program_access_client_calls_for_user_and_program(student_1, program)
    give_user_access_to_program(student_1, program)
    log_in_as(student_1)

    step 'Create an individually-assignable assignment, not assigned to ' \
         'the student' do
      create(
        :assignment,
        assignable: activity_1,
        category: category,
        due_date: future_due_date,
        individually_assignable: true,
        section: section
      )
    end

    step 'Create an individually-assignable assignment, assigned to the student' do
      create(
        :assignment,
        assignable: activity_2,
        category: category,
        due_date: future_due_date,
        individually_assignable: true,
        section: section
      )
      IndividualAssignment.create!(
        activity_id: activity_2.id,
        section_id: section.id,
        user_id: student_1.id
      )
    end

    step 'Create a regular, non-individually-assignable assignment' do
      create(
        :assignment,
        assignable: activity_3,
        category: category,
        due_date: future_due_date,
        individually_assignable: false,
        section: section
      )
    end

    purpose 'I do not see assignments for which I am not individually ' \
            'assigned on Supersite dashboard or in workset' do
      visit course_section_path(course_id: course.id, section_id: section.id)

      expect(page).to have_selector(
        '.test-assignment-count-expanded',
        text: '2 activities'
      )

      click_button('start')
      expect_correct_non_assessment_workset
    end

    purpose 'I do not see a due date for assignments for which I am not ' \
            'individually assigned in the student ToC' do
      visit section_toc_path(program_id: program.id, section_id: section.id)

      expect(page).to have_selector('h1')

      within(".test-activity-id-#{activity_1.id}") do
        expect(page).to have_selector(
          '.test-activity-due-date',
          exact_text: true,
          text: ''
        )
      end

      within(".test-activity-id-#{activity_2.id}") do
        expect(page).to have_selector(
          '.test-activity-due-date',
          text: future_due_date.strftime('%a %-m/%-d')
        )
      end
    end

    purpose 'I do not see due date in the activity shell for activities ' \
            'that are individually assigned but not to me' do
      visit section_activity_path(id: activity_1.id, section_id: section.id)

      expect(page).to have_no_selector('.test-activity-context-due-date')
      expect(page).to have_no_selector('.test-activity-modal-due-date')
    end

    purpose 'I do not see assignments for which I am not individually ' \
            'assigned on Vista Online Learning dashboard or in workset' do
      program.update!(family: 'vista_online_learning')

      visit course_section_path(course_id: course.id, section_id: section.id)

      expect(page).to have_selector(
        '.test-assignment-count',
        text: '2 activities'
      )

      click_button('Start')
      expect_correct_non_assessment_workset
    end

    purpose 'I do not see assignments for which I am not individually ' \
            'assigned on Supersite Junior dashboard or in workset' do
      program.update!(family: 'supersites_jr')

      visit jr_course_section_path(course_id: course.id, section_id: section.id)

      expect(page).to have_selector(
        '.test-assignment-count',
        text: '2 assignments'
      )

      click_button('Go')
      expect_correct_non_assessment_workset
    end

    step 'Ensure all assignments are overdue' do
      Assignment.all.each { |assignment| assignment.update!(due_date: 2.days.ago) }
    end

    purpose 'I do not see overdue assignments for which I am not individually ' \
            'assigned on Supersite dashboard or in workset' do
      program.update!(family: nil)

      visit course_section_path(course_id: course.id, section_id: section.id)

      expect(page).to have_text('Overdue')
      expect(page).to have_selector(
        '.test-assignment-count-expanded',
        text: '2 activities'
      )

      click_button('start')
      expect_correct_non_assessment_workset
    end

    purpose 'I do not see overdue assignments for which I am not individually ' \
            'assigned on Vista Online Learning dashboard or in workset' do
      program.update!(family: 'vista_online_learning')

      visit course_section_path(course_id: course.id, section_id: section.id)

      click_link('Previous Due Dates')

      expect(page).to have_selector(
        '.test-assignment-count',
        text: '2 activities'
      )

      click_button('Start')
      expect_correct_non_assessment_workset
    end

    purpose 'I do not see overdue assignments for which I am not individually ' \
            'assigned on Supersite Junior dashboard or in workset' do
      program.update!(family: 'supersites_jr')

      visit jr_course_section_path(course_id: course.id, section_id: section.id)

      expect(page).to have_text('You have overdue work.')

      click_button('Go')

      expect(page).to have_selector(
        '.test-lesson-to-do-count',
        text: '2 assignments'
      )

      click_button('Go')

      expect_correct_non_assessment_workset
    end

    lesson.toc_entries = lesson.toc_entries + [quiz_strand, test_strand, exam_strand]
    lesson.save!

    activity_1.update!(
      concept_id: quiz_concept.id,
      toc_location: quiz_strand.location
    )

    activity_2.update!(
      concept_id: test_concept.id,
      toc_location: test_strand.location
    )

    activity_3.update!(
      concept_id: exam_concept.id,
      toc_location: exam_strand.location
    )

    step 'Ensure all assignments are due in the future and released' do
      Assignment.all.each do |assignment|
        assignment.update!(due_date: future_due_date, show_at: 1.day.ago)
      end
    end

    purpose 'I do not see assessments for which I am not individually ' \
            'assigned on Supersite dashboard or assessments toc' do
      program.update!(family: nil)

      visit course_section_path(course_id: course.id, section_id: section.id)

      expect(assessment_labels('.test-lesson-link')).to contain_exactly(
        "#{lesson.name} | Test", "#{lesson.name} | Exam"
      )

      visit student_assessments_path(program_id: program.id, section_id: section.id)

      expect(
        assessment_labels('.test-assigned-assessment-title')
      ).to contain_exactly(
        "#{lesson.name} | Test", "#{lesson.name} | Exam"
      )
    end

    purpose 'I do not see assessments for which I am not individually ' \
            'assigned on Vista Online Learning dashboard or assessments ' \
            'toc' do
      program.update!(family: 'vista_online_learning')

      visit course_section_path(course_id: course.id, section_id: section.id)

      expect(assessment_labels('.test-strand-group-link')).to contain_exactly(
        "#{lesson.name} : Test", "#{lesson.name} : Exam"
      )

      # Portales uses the same assessments index logic as regular supersites,
      # so no need to test it separately.
    end

    purpose 'I do not see assessments for which I am not individually ' \
            'assigned on Supersite Junior dashboard or assessments toc' do
      program.update!(family: 'supersites_jr')

      visit jr_course_section_path(course_id: course.id, section_id: section.id)

      expect(assessment_labels('.test-strand-name')).to contain_exactly(
        'Test', 'Exam'
      )

      visit jr_section_assessments_path(section_id: section.id)

      expect(assessment_labels('.test-full-title')).to contain_exactly(
        "#{lesson.name}|Test", "#{lesson.name}|Exam"
      )

      create(
        :attempt_completed,
        activity: activity_1,
        section: section,
        user: student_1
      )

      create(
        :attempt_completed,
        activity: activity_2,
        section: section,
        user: student_1
      )

      create(
        :attempt_completed,
        activity: activity_3,
        section: section,
        user: student_1
      )

      visit jr_section_assessments_path(section_id: section.id)

      expect(assessment_labels('.test-assessment-link')).to contain_exactly(
        "#{lesson.name} | Test", "#{lesson.name} | Exam"
      )
    end

    purpose 'I do not see completed assessments for which I am not ' \
            'individually assigned on Supersite assessments toc' do
      program.update!(family: nil)

      visit student_assessments_path(program_id: program.id, section_id: section.id)

      click_button('Completed')

      expect(assessment_labels('.test-past-assessment-title')).to contain_exactly(
        "#{lesson.name} | Test", "#{lesson.name} | Exam"
      )
    end
  end

  scenario 'As a student, my dashboard views and worksets reflect my ' \
           'individual assignments with multiple due dates' do
    create(:active_enrollment, section: section, user: student_1)
    initialize_program_access_client_calls_for_user_and_program(student_1, program)
    give_user_access_to_program(student_1, program)
    log_in_as(student_1)

    past_due_date = 2.days.ago.to_date

    step 'Create an individually-assignable assignment assigned to ' \
         'the student without an individual due date' do
      create(
        :assignment,
        assignable: activity_1,
        category: category,
        due_date: future_due_date,
        individually_assignable: true,
        section: section
      )
      IndividualAssignment.create!(
        activity_id: activity_1.id,
        section_id: section.id,
        user_id: student_1.id
      )
    end

    step 'Create an individually-assignable assignment assigned to ' \
         'the student with an individual due date' do
      create(
        :assignment,
        assignable: activity_2,
        category: category,
        due_date: past_due_date,
        individually_assignable: true,
        section: section
      )
      IndividualAssignment.create!(
        activity_id: activity_2.id,
        due_date: future_due_date,
        section_id: section.id,
        user_id: student_1.id
      )
    end

    step 'Create a regular, non-individually-assignable assignment' do
      create(
        :assignment,
        assignable: activity_3,
        category: category,
        due_date: future_due_date,
        individually_assignable: false,
        section: section
      )
    end

    purpose 'I see assignments assigned to me individually with an ' \
            'individual due date on the Supersite dashboard' \
            'and in worksets' do
      visit course_section_path(course_id: course.id, section_id: section.id)

      expect(page).to have_no_text('Overdue')

      expect(page).to have_selector(
        '.test-assignment-count-expanded',
        text: '3 activities'
      )

      click_button('start')

      expect_correct_multi_due_date_non_assessment_workset
    end

    purpose 'I see assignments assigned to me individually with an ' \
            'individual due date on the Vista Online Learning dashboard ' \
            'and in worksets' do
      program.update!(family: 'vista_online_learning')

      visit course_section_path(course_id: course.id, section_id: section.id)

      expect(page).to have_selector(
        '.test-assignment-count',
        text: '3 activities'
      )

      click_button('Start')

      expect_correct_multi_due_date_non_assessment_workset
    end

    purpose 'I see assignments assigned to me individually with an ' \
            'individual due date on the Supersite Junior dashboard ' \
            'and in worksets' do
      program.update!(family: 'supersites_jr')

      visit jr_course_section_path(course_id: course.id, section_id: section.id)

      expect(page).to have_selector(
        '.test-assignment-count',
        text: '3 assignments'
      )

      click_button('Go')
      expect_correct_multi_due_date_non_assessment_workset
    end
  end
end
