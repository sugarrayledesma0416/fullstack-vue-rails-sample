require 'new_student_dashboard_controller'

feature 'Student workset', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:school) { create(:school) }
  let(:program) { create(:program) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:unit) { create(:unit_with_lessons, program: program) }
  let(:lesson) { unit.lessons.first }
  let(:course) do
    create(
      :course,
      owner: instructor,
      program: program,
      school: school,
      first_unit: unit,
      last_unit: unit
    )
  end
  let(:section) { create(:section, instructor: instructor, course: course) }
  let(:seven_days_from_today) { 7.days.from_now.to_date }
  let(:category) { create(:category, course: course) }

  before do
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)
    content_filepath = File.join('spec', 'fixtures', 'xml', 'open_ended.xml')
    allow(Activity).to receive(:filepath_from_revision_id).and_return(content_filepath)
  end

  def assign_activity(activity:, **attrs)
    default_attrs = {
      assignable: activity,
      due_date: 2.days.from_now.to_date,
      section: section,
      show_at: 1.day.ago,
      category: category
    }
    create(:assignment, default_attrs.merge(attrs))
  end

  def create_assignments
    @activity_1 = create(:activity, activity_location_attributes(program, lesson: lesson))
    @activity_2 = create(:activity, activity_location_attributes(program, lesson: lesson))
    @activity_3 = create(:activity, activity_location_attributes(program, lesson: lesson))
    @activity_4 = create(:activity, activity_location_attributes(program, lesson: lesson))

    assign_activity(activity: @activity_1, due_date: seven_days_from_today)
    assign_activity(activity: @activity_2, due_date: seven_days_from_today)
    assign_activity(activity: @activity_3, due_date: seven_days_from_today)
    assign_activity(activity: @activity_4, due_date: seven_days_from_today)
  end

  def create_unassign_activities
    @unassigned_activity_1 = create(
      :activity, activity_location_attributes(program, lesson: lesson)
    )
    @unassigned_activity_2 = create(
      :activity, activity_location_attributes(program, lesson: lesson)
    )
    @unassigned_activity_3 = create(
      :activity, activity_location_attributes(program, lesson: lesson)
    )
    @unassigned_activity_4 = create(
      :activity, activity_location_attributes(program, lesson: lesson)
    )
  end

  def update_activity_attempt_status(activity, status)
    current_attempt = Attempt.where(activity_id: activity,
                                    section_id: section,
                                    user_id: student).first
    if current_attempt
      current_attempt.update(status_code: status)
    else
      create(
        :attempt,
        status_code: status,
        activity: activity,
        user: student,
        section: section
      )
    end
  end
  scenario 'Student workset' do
    step 'I log in as a student'

    step 'Setup the database' do
      step 'Create a course with assignments' do
        step 'Create a program with a lesson plan'
        step 'The student is in a course for that program' do
          create(:active_enrollment, section: section, user: student)
        end
        step 'Create assignments for this course' do
          create_assignments
        end
      end
      step 'Create 4 unassigned activities' do
        create_unassign_activities
      end
    end

    purpose 'Clicking on a bank of assignments shows me the first activity \
      in the bank' do
      step 'Go to the show page for the section' do
        visit course_section_path(course, section)
      end
      find('.test-start-button').click
      step 'I see the first activity in the bank' do
        expect(page).to have_selector('.test-activity-title')
        expect(page).to have_content(@activity_1.title)
      end
      step 'I see the assignment date in the header in a normalized fashion' do
        day = seven_days_from_today.day.ordinalize
        date = seven_days_from_today.strftime("DUE %B #{day}")
        expect(find('.c-activity-context__due-date')).to have_content(date)
      end
    end

    purpose 'The list of activities in a workset is displayed within an activity' do
      find('.test-show-assignments').click
      step 'I see a list of 4 activities in the bank' do
        within(page.find('.test-workset')) do
          expect(all('.test-group').count).to eq(4)
        end
      end
      step 'I see the current activity (the 1st one) highlighted' do
        expect(page).to have_selector(
          '.test-workset .test-group .is-current .test-current-activity-title'
        )
        expect(page).to have_content(@activity_1.title)
      end
      step 'I see the 2nd, 3rd and 4th activities as "unopened"' do
        within(page.find('.test-workset')) do
          second_activity = page.find('.test-group:nth-of-type(2) .test-assignment-group')
          third_activity = page.find('.test-group:nth-of-type(3) .test-assignment-group')
          fourth_activity = page.find('.test-group:nth-of-type(4) .test-assignment-group')
          expect(second_activity).to have_selector('.is-unopened')
          expect(third_activity).to have_selector('.is-unopened')
          expect(fourth_activity).to have_selector('.is-unopened')
        end
      end
      step 'Mark the 2nd activity as completed in the database' do
        update_activity_attempt_status(@activity_2, AttemptStatus::CODE_COMPLETED)
      end
      step 'Mark the 3rd activity as submitted in the database' do
        update_activity_attempt_status(@activity_3, AttemptStatus::CODE_SUBMITTED)
      end

      step 'Clear localStorage before navigating the workset' do
        # We need to do this, to make sure that the workset is open (as is the default) when
        # the user opens an activity for first time.
        page.execute_script('localStorage.clear()')
        page.refresh
      end

      step 'Click the link for the 4th activity' do
        within(page.find('.test-workset')) do
          expect(page).to have_content(@activity_4.title)
          find('.test-group:nth-of-type(4) .test-activity-title-link').click
        end
      end
      step 'I see the 1st activity as "opened"' do
        expect(page).to have_selector('.test-workset .test-group:nth-of-type(1) .is-opened')
      end
      step 'I see the 2nd activity as "completed"' do
        expect(page).to have_selector('.test-workset .test-group:nth-of-type(2) .is-completed')
      end
      step 'I see the 3rd activity as "incomplete"' do
        expect(page).to have_selector('.test-workset .test-group:nth-of-type(3) .is-incomplete')
      end
    end

    purpose 'When accessing worksets from the course dashboard,' \
             'they do not include completed activities' do
      find('.test-show-assignments').click
      step 'Go to the show page for the section' do
        click_link('Return to Dashboard')
      end
      find('.test-start-button').click
      step 'I see a list of 3 activities in the bank' do
        within(page.find('.test-workset')) do
          expect(all('.test-group').count).to eq(3)
        end
      end
      step 'I see the 1st activity highlighted' do
        expect(page).to have_selector('.test-workset .test-group .is-current')
        expect(page).to have_content(@activity_1.title)
      end
      step 'I see the 2nd activity as "incomplete"' do
        expect(page).to have_selector(
          '.test-workset .test-group:nth-of-type(2) .is-incomplete'
        )
      end
      step 'I see the 3rd activity as "opened"' do
        expect(page).to have_selector('.test-workset .test-group:nth-of-type(3) .is-opened')
      end
    end

    purpose 'When accessing a workset with no assignments, I see an error message' do
      step 'Mark all activities as completed in the database' do
        update_activity_attempt_status(@activity_1, AttemptStatus::CODE_COMPLETED)
        update_activity_attempt_status(@activity_3, AttemptStatus::CODE_COMPLETED)
        update_activity_attempt_status(@activity_4, AttemptStatus::CODE_COMPLETED)
      end
      step 'Access an activity bank with no uncompleted assignments' do
        click_link('Return to Dashboard')
      end
      step 'I see "There are no uncompleted assignments due on"' do
        expect(page).to have_selector(
          '#_current_assignments .act_count_container .act_count', text: '0'
        )
        expect(page).to have_selector(
          '#_current_assignments .action', text: 'All assignments completed'
        )
      end
    end

    purpose 'When opening a workset for all my past due assignments, ' \
            'I see a list of all my past due activities' do
      step 'Create a course with only 2 days of past assignments in the database' do
        assign_activity(activity: @unassigned_activity_1, due_date: 2.days.ago, section: section)
        assign_activity(activity: @unassigned_activity_2, due_date: 2.days.ago, section: section)
        assign_activity(activity: @unassigned_activity_3, due_date: 2.days.ago, section: section)
        assign_activity(activity: @unassigned_activity_4, due_date: 2.days.ago, section: section)
      end

      step 'Go to the show page for the section' do
        visit course_section_path(course, section)
      end

      step 'Expand the overdue date' do
        find('.test-plus-icon-0').click
      end

      step 'Click on the "start" button of the first assignment' do
        find('.test-start-button').click
      end

      step 'I see a list of all of my past due activities' do
        within(page.find('.test-workset')) do
          expect(all('.test-group').count).to eq(4)
        end
        expect(page).to have_selector(
          '.test-workset .test-group:nth-of-type(1)', text: @unassigned_activity_1.title
        )
        expect(page).to have_selector(
          '.test-workset .test-group:nth-of-type(2)', text: @unassigned_activity_2.title
        )
        expect(page).to have_selector(
          '.test-workset .test-group:nth-of-type(3)', text: @unassigned_activity_3.title
        )
        expect(page).to have_selector(
          '.test-workset .test-group:nth-of-type(4)', text: @unassigned_activity_4.title
        )
      end
    end
  end
end
