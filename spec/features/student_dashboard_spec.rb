feature 'Student dashboard', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  around(:each, reset_time_zone: true) do |example|
    original_time_zone = Time.zone
    example.run
    Time.zone = original_time_zone
  end

  let(:school) { create(:school) }
  let(:program) { create(:program) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, unit:) }
  let(:course) { create(:course, owner: instructor, program:, school:) }
  let(:section) { create(:section, instructor:, course:) }
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

  def student_dashboard_url
    course_section_path(course, section)
  end

  context 'when logged in as a student' do
    before do
      initialize_program_access_client_calls_for_user_and_program(student, program, true)
      give_user_access_to_program(student, program, true)
      log_in_as(student)
    end

    def assign_activity(activity:, **attrs)
      default_attrs = {
        assignable: activity,
        due_date: 2.days.from_now.to_date,
        section:,
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
            create(:active_enrollment, section:, user: student)
          end
          step 'Create past, current and future assignments for this course' do
            create_assignments
          end
        end
      end

      purpose 'I can see accessibility features link' do
        step 'Go to the show page for the section' do
          visit student_dashboard_url
        end
        step 'I can see accessibility features link' do
          expect(page).to have_link('Accessibility Features')
        end
      end

      purpose 'I see a list of assignments to complete' do
        step 'Go to the show page for the section' do
          visit student_dashboard_url
        end
        step 'I see a list of overdue assignments' do
          expect(page).to have_selector('.test-assignment-day', text: 'Overdue')
        end
        step 'I see 2 groups of upcoming assignments' do
          check_due_assignment(lesson.activities[0].assignments[0].due_date.wday)
          check_due_assignment(lesson.activities[1].assignments[0].due_date.wday)
        end
      end

      purpose "I see a list of current assignments relative to the section's timezone" do
        step  'Set the student\'s section timezone to "Pacific Time (US & Canada)"' do
          section.time_zone = 'Pacific Time (US & Canada)'
        end
        step 'Set a due time of "23:59:00"' do
          section.due_time = '23:59:00'
          section.save!
          student.sections.reload
        end
        step 'Set the webserver timezone to "Atlantic Time (Canada)"' do
          Time.zone = 'Atlantic Time (Canada)'
        end
        Timecop.travel(Time.now.midnight + 1.day + 1.minute) do
          step 'Set the webserver just after midinight'
          step 'Go to the show page for the section' do
            visit student_dashboard_url
          end
          step 'I see the correct next current assignment' do
            check_due_assignment(lesson.activities[0].assignments[0].due_date.wday)
            check_due_assignment(lesson.activities[1].assignments[0].due_date.wday)
          end
        end
      end

      purpose 'I always see the next 2 assignment dates even after completing them' do
        step 'mark the current assignment as completed in the database' do
          create(
            :attempt_completed,
            activity: lesson.activities[1],
            section:,
            user: student
          )
        end
        step 'Go to the show page for the section' do
          visit student_dashboard_url
        end
        step 'I see 2 groups of upcoming assignments' do
          expect(page).to have_css('.test-no-due-date')
          expect(page).to have_text('All assignments completed')
          check_due_assignment(lesson.activities[1].assignments[0].due_date.wday)
        end
      end

      purpose 'I see list of announcement when they are defined' do
        # TODO: this is a random date. Find out why it fails after 11:30 PM BOS constantly.
        # It also fails randomly during the day.
        Timecop.freeze('2020-05-01 05:00:00') do
          step 'setup announcements' do
            # covers test cases for past and future calendered announcements
            announcement = create(:announcement, title: 'future/past', class_cancelled: false)
            cancelled_class_announcement = create(:announcement, title: 'future/past class cancelled', class_cancelled: true)

            # covers test cases for present day calendered announcements
            present_announcement = create(:announcement, title: 'present day', show_on: Time.now.to_date, class_cancelled: false)
            cancelled_class_present_announcement = create(:announcement, title: 'class cancelled today', show_on: Time.now.to_date, class_cancelled: true)

            create(:announcement_posted_notification, user: student, section:, announcement:)
            create(:announcement_posted_notification, user: student, section:, announcement: cancelled_class_announcement)
            create(:announcement_posted_notification, user: student, section:, announcement: present_announcement)
            create(:announcement_posted_notification, user: student, section:, announcement: cancelled_class_present_announcement)
          end

          step 'all announcements are visible on class Bulletin' do
            visit student_dashboard_url
            within(find('.test-announcement-bulletin')) do
              expect(page).to have_text('future/past')
              expect(page).to have_text('future/past class cancelled')
              expect(page).to have_text('present day')
              expect(page).to have_text('class cancelled today')
            end
          end

          step 'only today calendered announcements are visible on banner' do
            visit student_dashboard_url
            within(find('.test-banner-announcements')) do
              expect(page).not_to have_text('future/past')
              expect(page).not_to have_text('future/past class cancelled')
              expect(page).to have_text('present day')
              expect(page).to have_text('class cancelled today')
            end
          end
        end
      end
    end

    scenario 'As a student I can see assessment label' do
      step 'Setup the database' do
        step 'Create course with past, current and future assignments for this student' do
          create(:active_enrollment, section:, user: student)
          create_assignments
        end
        step 'Create and assign 2 activities in an assessment strand with a ' \
             'singular label of "quiz"' do
          activity_quiz_1 = create(
            :activity,
            assessment_location_attributes(
              program,
              lesson:,
              singular_label: 'quiz'
            )
          )
          activity_quiz_2 = create(
            :activity,
            assessment_location_attributes(
              program,
              lesson:,
              singular_label: 'quiz',
              strand_id: activity_quiz_1.toc_location
            )
          )
          assign_activity(activity: activity_quiz_1, due_date: 2.days.from_now.to_date)
          assign_activity(activity: activity_quiz_2, due_date: 2.days.from_now.to_date)
        end
      end

      purpose 'I can see assessment label' do
        step 'Go to the show page for the section' do
          visit student_dashboard_url
        end
        step 'I see "2 quizzes" as a part of assignment' do
          expect(page).to have_selector('.test-assignment-count-expanded', text: '2 quizzes')
        end
      end
    end

    scenario 'As a student I can see additional entries set by the program manager' do
      step 'Setup the database' do
        step 'Create course with past, current and future assignments for this student' do
          step 'The student is in a course for that program' do
            create(:active_enrollment, section:, user: student)
            create_assignments
          end
          step 'Create additional menu entries' do
            ProgramConfig.create!(
              program_settings.merge(
                creator_id: create(:user).id,
                program_id: program.id
              )
            )
          end
        end
      end

      purpose 'I can see the additional entries' do
        step 'Go to the show page for the section' do
          visit student_dashboard_url
        end
        step 'I see the additional entry for students' do
          expect(page).to have_selector(
            "a[href='#{program_settings[:content_menu_additional_entries][0][:url]}'][data-link-type='vtext']",
            text: program_settings[:content_menu_additional_entries][0][:label]
          )
        end
        step 'I do not see the additional entry for instructors' do
          expect(page).not_to have_selector(
            "a[href='#{program_settings[:content_menu_additional_entries][1][:url]}']",
            text: program_settings[:content_menu_additional_entries][1][:label]
          )
        end
      end
    end

    context 'when program config manager hid menu content' do
      scenario 'As student, I cannot see hidden content menu' do
        step 'Setup the database' do
          step 'Create course with past, current and future assignments for this student' do
            step 'The student is in a course for that program' do
              create(:active_enrollment, section:, user: student)
              create_assignments
            end
            step 'Create additional menu entries' do
              ProgramConfig.create!(
                program_settings_hide.merge(
                  creator_id: create(:user).id,
                  program_id: program.id
                )
              )
            end
          end
        end
        purpose 'I cannot see the hidden menu entries' do
          step 'go to the show page for the section' do
            visit student_dashboard_url
          end
          step 'I cannot see activities menu entry' do
            expect(page).not_to have_selector(
              "a[href='#{main_app.section_toc_path(section || 0, program)}']",
              text: 'Activities'
            )
          end
        end
      end

      scenario 'As student, I can see the menu entries' do
        step 'Setup the database' do
          step 'Create course with past, current and future assignments for this student' do
            step 'The student is in a course for that program' do
              create(:active_enrollment, section:, user: student)
              create_assignments
            end
            step 'Create additional menu entries' do
              ProgramConfig.create!(
                program_settings.merge(
                  creator_id: create(:user).id,
                  program_id: program.id
                )
              )
            end
          end
        end
        purpose 'I can see the complete menu entries' do
          step 'Go to the show page for the section' do
            visit student_dashboard_url
          end
          step 'I can see activities menu entry' do
            expect(page).to have_selector(
              "a[href='#{main_app.section_toc_path(section || 0, program)}']",
              text: 'Activities'
            )
          end
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
          visit student_dashboard_url
        end
        step 'I am redirected to the instructor Dashboard' do
          url = page.current_url
          expect(url).not_to include student_dashboard_url
        end
      end
    end
  end
end
