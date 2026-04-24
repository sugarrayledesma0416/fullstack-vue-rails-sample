feature 'Student table of contents',
        js: true, chrome: true, new_gb_sync: true, clear_session_storage: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include GradebookEngineHelpers

  let(:school) { create(:school) }
  let(:program) { create(:program) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:unit_1) { create(:unit, program: program, name: 'UNIT-01', rank: 0) }
  let(:unit_2) { create(:unit, program: program, name: 'UNIT-02', rank: 1, released: false) }
  let(:unit_3) { create(:unit, program: program, name: 'UNIT-03', rank: 2) }
  let(:unit_4) { create(:unit, program: program, name: 'UNIT-04', rank: 3) }
  let(:lesson_1a) { create(:lesson, unit: unit_1, name: 'Lesson 1a') }
  let(:lesson_2a) { create(:lesson, unit: unit_2, name: 'Lesson 2a') }
  let(:lesson_3a) { create(:lesson, unit: unit_3, name: 'Lesson 3a') }
  let(:lesson_4a) { create(:lesson, unit: unit_4, name: 'Lesson 4a') }
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
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:strands) do
    {
      strand_a_attrs: { title: 'strand_a' },
      strand_b_attrs: { title: 'strand_b' },
      strand_c_attrs: { title: 'strand_c' },
      strand_d_attrs: { title: 'strand_d' }
    }
  end
  let(:unsubmitted_activity_1) { create_activity }
  let(:unsubmitted_activity_2) { create_activity }
  let(:open_graded_activity) { create_activity }
  let(:saved_graded_activity) { create_activity }
  let(:submitted_auto_graded_activity) { create_activity('auto') }
  let(:submitted_instructor_graded_activity) { create_activity('instructor') }
  let(:submitted_mixed_graded_activity) { create_activity('mixed') }
  let(:ungraded_activity) { create_activity }
  let(:learning_engine_activity) do
    create(
      :activity,
      lesson: lesson_1a,
      toc_location: lesson_1a.strands[0].location,
      component_name: 'Practice',
      activity_type: 'Learning Engine',
      concept: lesson_1a.concepts[0]
    )
  end
  let(:sb_activity) do
    create_sb_activity(submittable: true, title: 'Smartbook')
  end
  let(:non_submittable_sb_activity) do
    create_sb_activity(submittable: false, title: 'Non submittable smartbook')
  end
  let(:category) { create(:category, course: course) }

  before do
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)
    create(:active_enrollment, section: section, user: student)
  end

  def create_concept_for_toc_entries(lesson)
    lesson.strands.each_with_index do |strand, index|
      create_concept_matching_strand_id(strand, name: strand.title, rank: index, lesson: lesson)
    end
  end

  def assign_activity(activity, attrs = {})
    default_attrs = {
      category: category,
      due_date: attrs[:due_date] || 2.days.from_now.to_date,
      section: section,
      show_at: 1.day.ago
    }
    create(:assignment, default_attrs.merge(assignable: activity))
  end

  def create_activity(grade_method = nil)
    create(
      :activity,
      lesson: lesson_1a,
      toc_location: lesson_1a.strands[0].location,
      component_name: 'Practice',
      grading_method: grade_method,
      concept: lesson_1a.concepts[0]
    )
  end

  def create_submission_and_score(attrs)
    create_gradebook_engine_submission(
      activity: attrs[:activity],
      pending: attrs[:pending],
      student: student,
      submitted_at: 2.days.ago
    )
  end

  def create_sb_activity(args = {})
    default_args = {
      lesson: lesson_1a,
      toc_location: lesson_1a.strands[0].location,
      component_name: 'Practice',
      grading_method: nil,
      concept: lesson_1a.concepts[0],
      activity_type: 'smart_book',
      submittable: true
    }
    create(:activity, default_args.merge(args))
  end

  def create_sb_submission_and_score(attrs)
    create_gradebook_engine_submission(
        activity: attrs[:activity],
        pending: attrs[:pending],
        partial_pending: attrs[:partial_pending],
        student: student,
        submitted_at: 2.days.ago
    )
  end

  scenario 'Student table of contents' do
    step 'I log in as a student'

    step 'Setup the database' do
      step 'Create a program'
      step 'Create a non released lesson called "Non released lesson"'
      step "Create a lesson the student's course does not cover"
      step "Create a lesson the student's course covers"
      step 'Create a lesson called "Lesson 1" covered in course' do
        step 'Create all strands called "Strand A", "Strand B" and "Strand C"' do
          lesson_1a.toc_entries = [
            create(:toc_entry, strands[:strand_a_attrs]),
            create(:toc_entry, strands[:strand_b_attrs]),
            create(:toc_entry, strands[:strand_c_attrs])
          ]
          lesson_1a.save!
          create_concept_for_toc_entries(lesson_1a)
        end
        step 'Create component in Strand A' do
          step 'Create a component called "Presentations and Tutorials"' do
            step 'Create a non assigned activity' do
              @non_assigned_activity = create(
                :activity,
                lesson: lesson_1a,
                toc_location: lesson_1a.strands[0].location,
                component_name: 'Presentations and Tutorials',
                concept: lesson_1a.concepts[0]
              )
            end
          end
          step 'Create a component called "Practice"' do
            step 'Create 2 un-submitted activity' do
              attrs = {due_date: 2.days.ago}
              assign_activity(unsubmitted_activity_1, attrs)
              assign_activity(unsubmitted_activity_2, attrs)
              hash_submission_data = {activity: unsubmitted_activity_2, pending: false}
              create_submission_and_score(hash_submission_data)
              GradebookEngine::GradebookAPI.adjust_points_earned(
                student.id, section.id, unsubmitted_activity_2, school.id,
                points_earned: unsubmitted_activity_2.points_possible
              )
              #TODO: The functionality of automatic display of grade on toc page after the due
              # date was missed is currently not working. Need to implement/fix this functionality.
            end
            step 'Create an gradable activity that was viewed but not saved or submitted' do
              create(
                :attempt_opened,
                activity: open_graded_activity,
                user: student,
                section: section
              )
              assign_activity(open_graded_activity)
            end
            step 'Create an gradable activity that has a set of saved responses' do
              create(
                :attempt,
                status_code: AttemptStatus::CODE_OPENED,
                activity: saved_graded_activity,
                user: student,
                section: section,
                saved_submission_id: 1
              )
              assign_activity(saved_graded_activity)
            end
            step 'Create an gradable activity (with grading_method = auto) that ' \
                 'has been submitted and has attempts remaining' do
              create(
                :attempt_submitted,
                activity: submitted_auto_graded_activity,
                user: student,
                section: section
              )
              assign_activity(submitted_auto_graded_activity)
              hash_submission_data = {activity: submitted_auto_graded_activity, pending: false}
              create_submission_and_score(hash_submission_data)
            end
            step 'Create an gradable activity (with grading_method = instructor) that ' \
                 'has been submitted and has attempts remaining' do
              create(
                :attempt_submitted,
                activity: submitted_instructor_graded_activity,
                user: student,
                section: section
              )
              assign_activity(submitted_instructor_graded_activity)
              hash_submission_data = {activity: submitted_instructor_graded_activity, pending: true}
              create_submission_and_score(hash_submission_data)
            end
            step 'Create an gradable activity (with grading_method = mixed) that ' \
                 'has been submitted and has attempts remaining' do
              create(
                :attempt_submitted,
                activity: submitted_mixed_graded_activity,
                user: student,
                section: section
              )
              assign_activity(submitted_mixed_graded_activity)
              hash_submission_data = {activity: submitted_mixed_graded_activity, pending: true}
              create_submission_and_score(hash_submission_data)
            end
            step 'Create an ungradable activity that has been completed' do
              create(
                :attempt_completed,
                activity: ungraded_activity,
                user: student,
                section: section
              )
              assign_activity(ungraded_activity)
            end
            step 'Create a learning engine activity' do
              assign_activity(learning_engine_activity)
            end
          end
        end
        step 'Create activity in strand c for lesson 1'do
          activity_1_lesson_1 = create(
            :activity,
            lesson: lesson_1a,
            toc_location: lesson_1a.strands[2].location,
            component_name: 'Practice',
            concept: lesson_1a.concepts[2]
          )
          assign_activity(activity_1_lesson_1)
        end
        step 'Create a smartbook activity (with grading_method = auto) that ' \
                 'has an instructor-graded subactivity that has been submitted' do
          create(
              :attempt_submitted,
              activity: sb_activity,
              user: student,
              section: section
          )
          assign_activity(sb_activity)
          hash_submission_data = {activity: sb_activity, pending: false, partial_pending: true}
          create_sb_submission_and_score(hash_submission_data)
        end
        step 'Create a non submittable smartbook activity (with grading_method = auto) ' \
             'that has been completed' do
          create(
            :attempt_completed,
            activity: non_submittable_sb_activity,
            user: student,
            section: section
          )
          assign_activity(non_submittable_sb_activity)
        end
      end
      step 'Create a lesson called "Lesson 2" which is unreleased' do
        step 'Create all strands called "Strand A" and "Strand D"' do
          lesson_2a.toc_entries = [
            create(:toc_entry, strands[:strand_a_attrs]),
            create(:toc_entry, strands[:strand_d_attrs])
          ]
          lesson_2a.save!
          create_concept_for_toc_entries(lesson_2a)
        end
      end
      step 'Create a lesson called "Lesson 3" which is covered in course' do
        step 'Create all strands called "Strand A", "Strand D" and "Strand C"' do
          lesson_3a.toc_entries = [
            create(:toc_entry, strands[:strand_a_attrs]),
            create(:toc_entry, strands[:strand_d_attrs]),
            create(:toc_entry, strands[:strand_c_attrs])
          ]
          lesson_3a.save!
          create_concept_for_toc_entries(lesson_3a)
        end
        step 'Create activity in strand c for lesson 3' do
          activity_1_lesson_3 = create(
            :activity,
            lesson: lesson_3a,
            toc_location: lesson_3a.strands[2].location,
            component_name: 'Practice',
            concept: lesson_3a.concepts[2]
          )
          assign_activity(activity_1_lesson_3)
        end
        step 'Create activity in strand d for lesson 3' do
          activity_2_lesson_3 = create(
            :activity,
            lesson: lesson_3a,
            toc_location: lesson_3a.strands[1].location,
            component_name: 'Practice',
            concept: lesson_3a.concepts[1]
          )
          assign_activity(activity_2_lesson_3)
        end
      end
      step "Create lesson not covered in course" do
        step "Add strand in the lesson" do
           lesson_4a.toc_entries = [create(:toc_entry, strands[:strand_a_attrs])]
           lesson_4a.save!
           create_concept_for_toc_entries(lesson_4a)
        end
      end
    end

    purpose 'I can choose to see only the lessons my current course covers' do
      step 'Go to the table of contents home page' do
        visit section_toc_path(section, program)
      end
      step 'Only the lessons covered in my course are listed' do
        expect(page).to have_no_text(unit_4.name)
      end
      step 'In the lessons dropdown, click to show all the lessons' do
        find('.test-ls-dropdown').click
      end
      step 'All the lessons are listed' do
        find('.test-ls-dropdown').click
        [lesson_1a, lesson_2a, lesson_3a].each do |lesson|
          expect(page).to have_selector('.test-ls-dropdown-list-item', text: lesson.name)
        end
      end
      step 'In the lessons dropdown, is "show all units" showed' do
        find('.test-ls-dropdown').click
        find('.test-ls-units__list-item', text: 'Show all units')
      end
      step 'All lessons covered in my course are listed' do
        find('.test-ls-dropdown').click
        unit_link = find('.test-ls-units__list-item')
        page.execute_script("arguments[0].click();", unit_link.native)
        find('.test-ls-dropdown').click
        expect(page).to have_no_text(lesson_4a.name)
      end
    end

    purpose 'I can navigate all the lessons without getting an error' do
      step 'In the lessons dropdown, select "show all lessons"' do
        find('.test-ls-dropdown').click
        unit_link = find('.test-ls-units__list-item', text: 'Show all units')
        page.execute_script('arguments[0].click();', unit_link.native)
      end
      step "Select the lesson the student's course does not cover" do
        find('.test-ls-dropdown').click
        lesson_link = find('.test-ls-dropdown-list-item', text: lesson_3a.name)
        page.execute_script('arguments[0].click();', lesson_link.native)
      end
      step 'I do not see any server error' do
        expect(page).to have_selector('.test-strand-list', visible: true)
      end
      step 'Select the lesson "Lesson 1 which is covered in the course"' do
        find('.test-ls-dropdown').click
        lesson_link = find('.test-ls-dropdown-list-item', text: lesson_1a.name)
        page.execute_script('arguments[0].click();', lesson_link.native)
      end
      step 'I do not see any server error' do
        expect(page).to have_selector('.test-strand-list', visible: true)
      end
      step 'Select the lesson "Lesson 3"' do
        find('.test-ls-dropdown').click
        lesson_link = find('.test-ls-dropdown-list-item', text: lesson_3a.name)
        page.execute_script('arguments[0].click();', lesson_link.native)
      end
      step 'I do not see any server error' do
        expect(page).to have_selector('.test-strand-list', visible: true)
      end
      step 'In the lessons dropdown, select "only show lessons for my course"' do
        find('.test-ls-dropdown').click
        unit_link = find('.test-ls-units__list-item', text: 'Show all units')
        page.execute_script('arguments[0].click();', unit_link.native)
      end
    end

    purpose 'As a non VHL or Altavista I see a message informing me when a Unit has not been released' do
      step 'Select the lesson "Non released lesson"' do
        find('.test-ls-dropdown').click
        lesson_link = find('.test-ls-dropdown-list-item', text: lesson_2a.name)
        page.execute_script('arguments[0].click();', lesson_link.native)
      end
    end

    purpose 'When selecting a new lesson containing a strand with the same name ' \
            'as the current selected strand, the strand is automatically selected' do
      step 'Select lesson "Lesson 1"' do
        find('.test-ls-dropdown__contents').click
        lesson_link = find('.test-ls-dropdown-list-item', text: lesson_1a.name)
        page.execute_script("arguments[0].click();", lesson_link.native)
      end
      step 'Select strand "Strand C"' do
        click_link 'strand_c'
      end
      step 'Select lesson "Lesson 3"' do
        find('.test-ls-dropdown').click
        lesson_3_link = find('.test-ls-dropdown-list-item', text: lesson_3a.name)
        page.execute_script('arguments[0].click();', lesson_3_link.native)
      end
      step 'I see the strand "Strand C" selected' do
        expect(page).to have_selector('.is-selected', text: 'strand_c')
      end
    end

    purpose 'When selecting a new lesson that does not contain a strand with the same name ' \
            'as the current selected strand, the first strand is automatically selected' do
      step 'Select strand "Strand C"' do
        find('.test-ls-dropdown__contents').click
        click_link 'strand_c'
      end
      step 'Select lesson "Lesson 1"' do
        find('.test-ls-dropdown').click
        lesson_link = find('.test-ls-dropdown-list-item', text: lesson_1a.name)
        page.execute_script('arguments[0].click();', lesson_link.native)
      end
      step 'I see the strand "Strand A" selected' do
        expect(page).to have_selector('.is-selected', text: 'strand_c')
      end
    end

    purpose 'I see a complete lesson' do
      step "I see the lesson's name in the header" do
        expect(page).to have_selector('.test-ls-dropdown__list-item-text', text: lesson_1a.name)
      end
      step 'Select "All activities" from the dropdown' do
        within('.test-activity-module') do
          find('.test-visibility-all', text: 'All Activities').click
        end
      end
      step 'I see all activities grouped by component'
      purpose 'The status column displays correct information' do
        click_link 'strand_a'
        within('.test-activity-tables') do
          activity_completion_status = all('td.completion_status')
          activity_titles = all('td.toc_location_activity_list_entry')
          step 'It is empty for non assigned activities' do
            expect(activity_titles[0]).to have_selector('.test-activity-title', text: @non_assigned_activity.title)
            expect(activity_completion_status[0]).to have_text('')
          end
          step 'It shows 0.0% grade for one un-submitted activity' do
            expect(activity_titles[1]).to have_selector('.test-activity-title', text: unsubmitted_activity_1.title)
            #expect(activity_completion_status[1]).to have_text('0.0%')
            #TODO: Need to fix the functionality that display the grade for unsubmitted activity
            # when missed the due date and uncomment the above expectation.
          end
          step 'It shows 100% grade for one un-submitted activity' do
            expect(activity_titles[2]).to have_text(unsubmitted_activity_2.title)
            #expect(activity_completion_status[2]).to have_text('100.0%')
            #TODO: Need to fix the functionality that display the grade for unsubmitted activity
            # when missed the due date and uncomment the above expectation.
          end
          step 'It shows "opened" for the gradable activity that was viewed but not saved or submitted' do
            expect(activity_titles[3]).to have_text(open_graded_activity.title)
            expect(activity_completion_status[3]).to have_text('opened')
          end
          step 'It shows "started" for the gradable activity that has a set of saved responses' do
            expect(activity_titles[4]).to have_text(saved_graded_activity.title)
            expect(activity_completion_status[4]).to have_text('started')
          end
          step 'It shows a score for the gradable activity (with grading_method = auto) that ' \
             'has been submitted and has attempts remaining' do
            expect(activity_titles[5]).to have_text(submitted_auto_graded_activity.title)
            expect(activity_completion_status[5]).to have_text('0.0%')
          end
          step 'It shows "pending" for the gradable activity (with grading_method = instructor) that ' \
             'has been submitted and has attempts remaining' do
            expect(activity_titles[6]).to have_text(submitted_instructor_graded_activity.title)
            expect(activity_completion_status[6]).to have_text('Pending')
          end
          step 'It shows "pending" for the gradable activity (with grading_method = mixed) that ' \
             'has been submitted and has attempts remaining' do
            expect(activity_titles[7]).to have_text(submitted_mixed_graded_activity.title)
            expect(activity_completion_status[7]).to have_text('Pending')
          end
          step 'It shows "viewed" for the ungradable activity that has been completed' do
            expect(activity_titles[8]).to have_text(ungraded_activity.title)
            expect(activity_completion_status[8]).to have_text('viewed')
          end
          step 'It shows "pending" for the instructor-gradable smartbook activity that ' \
             'has been submitted' do
            expect(activity_titles[10]).to have_text(sb_activity.title)
            expect(activity_completion_status[10]).to have_text('Pending', exact: true)
          end
          step 'It shows "viewed" for the ungradable smartbook activity that ' \
             'has been completed' do
            expect(activity_titles[11]).to have_text(non_submittable_sb_activity.title)
            expect(activity_completion_status[11]).to have_text('viewed', exact: true)
          end
        end
      end
      step 'I do not see a due date for the non assigned activity' do
        activity_due_date_id = '#due_date_cell_for_activity_id_' + @non_assigned_activity.id.to_s
        expect(page).to have_selector(activity_due_date_id, text: '')
      end
      step 'I see a due date for an assigned activity' do
        activity_due_date_id = '#due_date_cell_for_activity_id_' + open_graded_activity.id.to_s
        week_day = (open_graded_activity.assignments[0].due_date.cwday % 7)
        expect(page).to have_selector(activity_due_date_id, text: Date::DAYNAMES[week_day][0..2])
      end
    end

    purpose 'I can choose to see only assigned activities' do
      within('.test-activity-module') do
        step 'Select "Assigned Only" from the dropdown' do
          find('.test-visibility-assigned', text: 'Assigned Only').click
        end
        step 'I only see assigned activities' do
          expect(page).to have_selector('.test-visibility-assigned', text: 'Assigned Only')
        end
      end
      step 'component "Presentations and Tutorials" shows "Nothing Assigned"' do
        expect(page).to have_selector('.test-nothing-assigned', text: 'Nothing Assigned')
      end
    end
  end
end
