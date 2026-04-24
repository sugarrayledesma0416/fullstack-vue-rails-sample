feature 'Lti Student dashboard', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:platform) { create(:lti_rostering_platform, school: school) }
  let(:school) { create(:school) }
  let(:program) { create(:program) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson, unit: unit) }
  let(:course) { create(:course, owner: instructor, program: program, school: school) }
  let(:section) { create(:section, instructor: instructor, course: course) }
  let(:program_settings) do
    {
      content_menu_additional_entries: [
        { label: 'External student link', url: 'http://student.com', target_user: 'Student' },
        { label: 'External instructor link', url: 'http://instructor.com', target_user: 'Instructor' }
      ]
    }
  end

  let(:program_settings_hide) do
    {
      content_menu_additional_entries: [
        { label: 'External student link', url: 'http://student.com', target_user: 'Student' },
        { label: 'External instructor link', url: 'http://instructor.com', target_user: 'Instructor' }
      ],
      hide_activities: true
    }
  end

  context 'when logged in as a student' do
    before do
      initialize_program_access_client_calls_for_user_and_program(student, program)
      give_user_access_to_program(student, program)
      log_in_as(student)
    end

    def assign_activity(activity:, **attrs)
      default_attrs = {
        assignable: activity,
        due_date: 2.days.from_now.to_date,
        section: section,
        show_at: 1.day.ago
      }
      create(:assignment, default_attrs.merge(attrs))
    end

    def create_assignments
      activity_1 = create(:activity, activity_location_attributes(program, lesson: lesson))
      activity_2 = create(:activity, activity_location_attributes(program, lesson: lesson))
      activity_3 = create(:activity, activity_location_attributes(program, lesson: lesson))
      assign_activity(activity: activity_1, due_date: 2.days.from_now.to_date)
      assign_activity(activity: activity_2, due_date: Time.now.to_date)
      assign_activity(activity: activity_3, due_date: 2.days.ago.to_date, show_at: 3.days.ago)
    end

    def check_due_assignment(week_day)
      week_day = Date::ABBR_DAYNAMES[week_day]
      expect(page).to have_text(week_day)
    end

    scenario 'As a student, I see my course dashboard', reset_time_zone: true do
      step 'Setup the database' do
        step 'Create course with past, current and future assignments for this student' do
          step 'The student is in a course for that program' do
            create(:active_enrollment, section: section, user: student)
          end
          step 'Create past, current and future assignments for this course' do
            create_assignments
          end
        end
      end
      # Minimal page content testing to confirm that the Student
      # course dashboard is displayed correctly;
      # I do not know whether or not the launch guid will be important or not;
      # I noticed that it is passed in the current Lti-Adv calls from UA to M3;
      # I don't think it hurts anything to include it in the new ones.
      purpose 'I see a list of assignments to complete' do
        step 'Go to the show page for the section' do
          visit lti_student_dashboard_path(
            program_id: program.id,
            section_guid: section.guid
          )
          expect(page.title).to include('Dashboard')
        end
        step 'I see a list of overdue assignments' do
          expect(page).to have_selector('.test-assignment-day', text: 'Overdue')
        end
        step 'I see 2 groups of upcoming assignments' do
          check_due_assignment(lesson.activities[0].assignments[0].due_date.wday)
          check_due_assignment(lesson.activities[1].assignments[0].due_date.wday)
        end
      end
    end
  end

  context 'when logged in as instructor' do
    before do
      initialize_program_access_client_calls_for_instructor(instructor, program)
      log_in_as(instructor)
    end
    scenario 'As an instructor, I cannot view the student dashboard' do
      purpose 'I cannot view the student dashboard' do
        step 'Try to go to the student Dashboard' do
          visit lti_student_dashboard_path(
            program_id: program.id,
            section_guid: section.guid
          )

        end
        step 'I am redirected to the instructor Dashboard' do
          # TODO expected behavior to be defined
          url = page.current_url
          expect(url).not_to include lti_student_dashboard_path(
                                       program_id: program.id,
                                       section_guid: section.guid
                                     )
        end
      end
    end
  end
end
