feature 'Instructor course setup', js: true, chrome: true, new_gb_sync: true, downloads: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include GradebookEngineHelpers
  include RspecJsDownloadHelpers

  let(:school) { create(:school) }
  let(:program) do
    # NOTE: We create a VOL program to be able to see the custom/express course
    # setup selection.
    create(:vol_program).tap do |program|
      program.units = Array.new(3) do |index|
        name = "Leccion #{index + 1}"
        create(:unit_with_lesson_with_toc_entries, name: name, label: name, program: program)
      end
    end
  end
  let(:lessons) { program.units.flat_map(&:lessons) }
  let(:instructor) { create(:instructor, schools: [school]) }

  let(:existing_course) do
    create(
      :course,
      owner: instructor,
      program: program,
      school: school,
      first_unit: lessons.first.unit,
      last_unit: lessons.last.unit
    ).tap do |course|
      course.categories << create(:category, course: course, weighting_percent: 50)
      course.categories << create(:category, course: course, weighting_percent: 50)
    end
  end
  let!(:existing_section) { create(:section, course: existing_course, instructor: instructor) }
  let(:start_date) { Time.zone.today }
  let(:end_date) { 2.weeks.from_now.to_date }
  let(:incorrect_end_date) { (Time.zone.today - 1.day).to_date }
  let(:course_licenses) { [] }
  let(:course_package) do
    Maestro::CoursePackage.new(
      content_type: 'level',
      id: 1,
      name: 'Supersite'
    )
  end
  let(:course_name_75_characters) { '111111111122222222223333333333444444444455555555556666666666777777777788888' }
  let(:course_name_76_characters) { '1111111111222222222233333333334444444444555555555566666666667777777777888888' }
  let(:course_name) { 'course name' }
  let(:section_name_16_characters) { '0123456789012345' }
  let(:section_name_17_characters) { '01234567890123456' }
  let(:section_name) { 'section name' }
  let(:category_name_1) { 'Practice' }
  let(:category_name_2) { 'Quizzes' }
  let(:category_name_3) { 'Homework' }
  let(:category_name_16_characters) { '0123456789012345' }
  let(:course_name_edited) { 'course name edited' }
  let(:start_date_edited) { Time.zone.today }
  let(:end_date_edited) { 3.weeks.from_now.to_date }
  let(:invalid_date) { '22/22/2019' }
  let(:course_packages_by_course) { {} }

  before do
    course_packages_by_course[existing_course.guid] = [course_package]

    initialize_program_access_client_calls_for_instructor(instructor, program)
    allow(Maestro::CoursePackage).to receive(:all).and_return([])
    allow(Maestro::CoursePackage).to receive(:available_packages)
      .and_return([course_package.response])
    allow(Maestro::CoursePackage).to receive(:all_for_courses)
      .and_return(course_packages_by_course)
    allow(CourseLicenseCreatorWorker).to receive(:perform_async)
    allow(Maestro::UserLicense).to receive(:all_for_user_and_program)
      .with([], program.id)
      .and_return([])
    allow(Maestro::CourseLicense).to receive(:create)
    allow_any_instance_of(Program).to receive(:has_vocab_tutorials?).and_return(true)
    # Create the program configuration in the past to allow some tests to override
    # it (the active one is always the most recent one).
    Timecop.travel(1.minute.ago) do
      create(
        :vol_program_config,
        program: program,
        audio_transcripts: true
      )
    end

    log_in_as(instructor)
  end

  describe 'Google Classroom configuration in course settings' do
    context 'when editing the course if Google Classroom configuration is Enabled for school' do
      let(:school) { create(:school, share_to_google_classroom: true) }

      scenario 'I can see and edit Google Share option in course content settings' do
        purpose 'I can edit a course' do
          visit instructor_dashboard_path(program)

          with_element(InstructorDashboardPageObject.new(page)) do |pobject|
            with_element(pobject.course_contextual_menu(existing_course.name)) do |course_entry|
              course_entry.open_contextual_menu
              course_entry.edit_course
            end
          end
        end

        purpose 'Google Share option in the "Content" tab is visible' do
          with_element(select_edit_course_tab(:content)) do |pobject|
            step 'Click on the "Content" tab'
            step 'Google Share option is visible and set to enabled' do
              expect(pobject).to have_share_to_google_classroom_option
              expect(pobject.share_to_google_classroom).to be_truthy
            end
          end
        end

        purpose 'I can update Google Share option in course content setting' do
          with_element(select_edit_course_tab(:content)) do |pobject|
            pobject.share_to_google_classroom = false
            pobject.button(:save_changes).click
            expect(page).to have_selector(
              '.test-course-wizard-flash-notice', text: 'Successfully saved course settings.'
            )
          end
        end

        purpose 'Updated information have been saved' do
          step 'Visit the dashboard page' do
            visit instructor_dashboard_path(program)
          end

          step 'Edit the course' do
            with_element(InstructorDashboardPageObject.new(page)) do |pobject|
              with_element(pobject.course_contextual_menu(existing_course.name)) do |course_entry|
                course_entry.open_contextual_menu
                course_entry.edit_course
              end
            end
          end

          step 'Click on the "Content" tab' do
            with_element(select_edit_course_tab(:content)) do |pobject|
              step 'Google Share option is visible and set to disabled' do
                expect(pobject.share_to_google_classroom).to be_falsey
              end
            end
          end
        end
      end
    end

    context 'when editing the course if Google Classroom configuration is Disabled for school' do
      let(:school) { create(:school, share_to_google_classroom: false) }

      scenario 'I can not see Google Share option in course content settings' do
        purpose 'I can edit a course' do
          visit instructor_dashboard_path(program)

          with_element(InstructorDashboardPageObject.new(page)) do |pobject|
            with_element(pobject.course_contextual_menu(existing_course.name)) do |course_entry|
              course_entry.open_contextual_menu
              course_entry.edit_course
            end
          end
        end

        purpose 'Google Share option in the "Content" tab is not visible' do
          with_element(select_edit_course_tab(:content)) do |pobject|
            step 'Click on the "Content" tab'
            step 'Google Share option is not visible' do
              expect(pobject).to have_no_share_to_google_classroom_option
            end
          end
        end
      end
    end
  end

  scenario 'As an instructor, I can create a course using the advanced course setup' do
    step 'Visit the dashboard page' do
      visit instructor_dashboard_path(program)
    end

    step 'Click on "Add course"' do
      with_element(InstructorDashboardPageObject.new(page)) do |pobject|
        pobject.button(:add_course).click
        wait_for_ajax
      end
    end

    step 'Select "Advanced setup"' do
      with_element(CourseSetupPathPageObject.new(page)) do |pobject|
        pobject.button(:advanced_setup).click
        wait_for_ajax
      end
    end

    purpose 'I can go back to the course setup option page' do
      step 'Click on the "back" button' do
        with_element(CoursePageObject.new(page)) do |pobject|
          pobject.button(:back).click
        end
      end

      step 'I am on the course setup option page' do
        expect(page).to have_selector('h1', text: 'Course Setup')
      end
    end

    purpose 'I can cancel the course creation' do
      step 'I Select "Advanced setup"' do
        with_element(CourseSetupPathPageObject.new(page)) do |pobject|
          pobject.button(:advanced_setup).click
          wait_for_ajax
        end
      end

      step 'I cancel the course creation' do
        with_element(CoursePageObject.new(page)) do |pobject|
          pobject.button(:cancel).click
        end
      end

      step 'I am back to the dashboard' do
        expect(page).to have_current_path(instructor_dashboard_path(program))
      end
    end

    purpose 'I see an alert when I cancel the course creation' do
      step 'I click on "Add course"' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          pobject.button(:add_course).click
          wait_for_ajax
        end
      end

      step 'I select "Advanced setup"' do
        with_element(CourseSetupPathPageObject.new(page)) do |pobject|
          pobject.button(:advanced_setup).click
          wait_for_ajax
        end
      end

      with_element(CoursePageObject.new(page)) do |pobject|
        step 'Set a course name' do
          pobject.course_name = course_name
        end

        if ENV['NO_CHROME_UNLOAD'] == 'true'
          pobject.button(:cancel).click
        else
          step 'I see an alert when I cancel' do
            expect(accept_alert do
              pobject.button(:cancel).click
            end).to eq('')
          end
        end
      end

      step 'I am back to the dashboard' do
        expect(page).to have_current_path(instructor_dashboard_path(program))
      end
    end

    purpose 'I create a course' do
      step 'Click on "Add course"' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          pobject.button(:add_course).click
          wait_for_ajax
        end
      end

      step 'Select "Advanced setup"' do
        with_element(CourseSetupPathPageObject.new(page)) do |pobject|
          pobject.button(:advanced_setup).click
          wait_for_ajax
        end
      end

      purpose 'The course page' do
        with_element(CoursePageObject.new(page)) do |pobject|
          purpose 'A course name is required' do
            step 'The "next" button is disabled' do
              expect(pobject.button(:next)).to be_disabled
            end
            step 'Set a course name' do
              pobject.course_name = course_name
              expect(pobject).to have_error_message_hidden(:course_name_required)
            end
            step 'The "next" button is enabled' do
              expect(pobject.button(:next)).not_to be_disabled
            end
            step 'Delete the course name' do
              pobject.course_name = ''
            end
            step 'I see the message "Course name is required."' do
              expect(pobject).to have_error_message_visible(:course_name_required)
            end
            step 'Set a course name' do
              pobject.course_name = course_name
            end
            step 'Set a start date' do
              pobject.start_date = start_date
            end
            step 'Set a end date' do
              pobject.end_date = end_date
            end
            step 'The "next" button is enabled' do
              expect(pobject.button(:next)).not_to be_disabled
            end
          end

          purpose 'Course name cannot be longer than 75 characters' do
            step 'Set a course name of 75 characters' do
              pobject.course_name = course_name_75_characters
              expect(pobject).to have_error_message_hidden(:course_name_length)
            end
            step 'The "next" button is enabled' do
              expect(pobject.button(:next)).not_to be_disabled
            end
            step 'Set a course name of 76 characters' do
              pobject.course_name = course_name_76_characters
            end
            step 'I see the message "Your course name cannot be longer than 75 characters."' do
              expect(pobject).to have_error_message_hidden(:course_name_length)
            end
            step 'The "next" button is disabled' do
              expect(pobject.button(:next)).to be_disabled
            end
            step 'Set a valid course name' do
              pobject.course_name = course_name
            end
          end

          purpose 'I cannot set the end date to be before the start date' do
            expect(pobject).to have_error_message_hidden(:end_date_before_start_date)
            step 'Set the end date before the start date' do
              pobject.end_date = incorrect_end_date
            end
            step 'I see the message "Your end date cannot be before your start date."' do
              expect(pobject).to have_error_message_visible(:end_date_before_start_date)
            end
            step 'The "next" button is disabled' do
              expect(pobject.button(:next)).to be_disabled
            end
            step 'Set the end date after the start date' do
              pobject.end_date = end_date
            end
            step 'The "next" button is enabled' do
              expect(pobject).to have_error_message_hidden(:end_date_before_start_date)
              expect(pobject.button(:next)).not_to be_disabled
            end
            step 'Set the end date equal to the start date' do
              pobject.end_date = start_date
            end
            step 'I see the message "Your end date cannot be before your start date."' do
              expect(pobject).to have_error_message_visible(:end_date_before_start_date)
            end
            step 'The "next" button is disabled' do
              expect(pobject.button(:next)).to be_disabled
            end
            step 'Set the end date after after the start date' do
              pobject.end_date = end_date
            end
            step 'I do not see the message "Your end date cannot be before your start date."' do
              expect(pobject).to have_error_message_hidden(:end_date_before_start_date)
            end
            step 'The "next" button is enabled' do
              expect(pobject.button(:next)).not_to be_disabled
            end
          end

          purpose 'I can see a preview of the information seen by students when enrolling' do
            with_element(pobject.preview_as_student) do |preview|
              preview.show
              expect(preview.caption).to eq(
                'When your students enroll, they will see this:'
              )
              expect(preview.sections).to match(
                [
                  an_object_having_attributes(
                    instructor: instructor.last_name,
                    course: course_name,
                    section: 'Section...'
                  )
                ]
              )
              expect(preview.previous_sections).to match(
                [
                  an_object_having_attributes(
                    instructor: existing_section.instructor.last_name,
                    # course name is truncated to 18 characters followed by 3 dots.
                    course: existing_course.name,
                    # section name is truncated to 10 characters followed by 3 dots.
                    section: existing_section.name
                  )
                ]
              )
            end

            step 'click on the "next" button' do
              pobject.button(:next).click
              wait_for_ajax
            end
          end
        end
      end

      purpose 'The content page' do
        with_element(ContentPageObject.new(page)) do |pobject|
          purpose 'I can copy content settings from existing activities' do
            step '"Default settings" is selected' do
              expect(page).to have_selector('#previous_course_id option')
              course_option = all('#previous_course_id option').detect(&:selected?).text
              expect(course_option).to eq('Default settings')
            end
            step 'Select an instructor course' do
              select existing_course.name, from: 'previous_course_id'
            end
            step 'I see a checkbox "Copy instructor-created activities"' do
              within('.test-content-step-copy-created') do
                expect(page).to have_selector('input', id: 'Copy instructor created activities')
              end
            end
            step 'Select "Default settings"' do
              select 'Default settings', from: 'previous_course_id'
            end
          end
          purpose 'I cannot select an invalid lesson range' do
            step 'Select a start lesson' do
              pobject.first_unit = lessons[1].unit_name
            end
            step 'I cannot select an end lesson less than the start lesson' do
              expect(pobject.last_units).not_to include(lessons[0].unit_name)
              pobject.first_unit = lessons[0].unit_name
              expect(pobject.last_units).to include(lessons[0].unit_name)
              pobject.last_unit = lessons[2].unit_name
            end
          end

          purpose 'I can change translations settings' do
            step 'I can enable or disable vocab tutorial translations' do
              pobject.enable_vocab_tutorial_translations = false
              pobject.enable_vocab_tutorial_translations = true
            end
          end

          purpose 'I can change technical support options' do
            step 'I can allow or not students to submit score reviews' do
              pobject.allow_review_requests = true
              pobject.allow_review_requests = false
            end
            step 'I can allow or not students to submit help requests' do
              pobject.allow_help_requests = true
              pobject.allow_help_requests = false
            end
          end
          purpose 'I can change chat availability to students' do
            pobject.chat_availability = :never
            pobject.chat_availability = :always
          end
          purpose 'I can choose if students can see estimated times or not' do
            pobject.show_estimated_times = true
            pobject.show_estimated_times = false
          end
          step 'click on the "next" button' do
            pobject.button(:next).click
          end
        end
      end
      purpose 'The gradebook page' do
        with_element(GradebookPageObject.new(page)) do |pobject|
          purpose 'I can select to copy category settings from an other course' do
            step 'Select other course of instructor to copy category settings from' do
              select existing_course.name, from: 'previous_course_id'
            end
            step 'I see the categories from the selected course' do
              existing_course.categories.each do |category|
                expect(pobject.category_weighting_percent(category.name))
                  .to eq(category.weighting_percent.to_s)
              end
            end
            step 'Select "Basic course" to copy category settings from' do
              select 'Basic course', from: 'previous_course_id'
              # Capybara is not calculating the body.offsetHeight when the tutorial
              # expander is contracted, causing a display issue and JS issues.
              # So we expand it.
              page.find('.expander__button').click
            end
            step 'I see the categories from the Basic course' do
              expect(pobject.category_weighting_percent('Homework')).to eq('100')
            end
            step 'The "next" button is not disabled' do
              expect(pobject.button(:next)).not_to be_disabled
            end
          end
          purpose 'I can use the gradebook categories tutorial' do
            expect(page).to have_field('previous_course_id')
            select 'Default settings', from: 'previous_course_id'
            step 'I see an explanation of what a category is' do
              expect(page).to have_selector('div', text: 'What is a category?')
            end
            step 'Click on the "get started" button' do
              pobject.button(:get_started).click
            end
            step 'I see a tooltip on the "add category" button' do
              expect(page).to have_selector(
                '.test-add-category-btn-hover',
                text: 'Click here to begin adding categories to your gradebook.',
                visible: false
              )
            end
            step 'The "next" button is disabled' do
              expect(pobject.button(:next)).to be_disabled
            end

            pobject.view_tutorial

            step 'I see an explanation of what a category is' do
              expect(page).to have_selector('div', text: 'What is a category?')
            end
            step 'I see the "get started" button' do
              expect(pobject.button(:get_started)).to be_enabled
            end

            pobject.hide_tutorial
            sleep 1
          end

          purpose 'I can add gradebook categories' do
            step 'Create 2 categories' do
              [category_name_1, category_name_2].each do |name|
                pobject.button(:add_category).click

                with_element(pobject.add_category_modal) do |category|
                  category.name = name
                  category.button(:next).click
                  category.weighting_percent = '50'
                  5.times { category.button(:next).click }

                  category.save
                  expect(pobject).to have_no_edit_category_modal
                end
              end
            end

            step 'Click on the "add category" button' do
              pobject.button(:add_category).click
            end
            step 'I see a modal'
            with_element(pobject.add_category_modal) do |category|
              purpose 'A name is required' do
                step 'The "next" button is disabled' do
                  expect(category.button(:next)).to be_disabled
                end
                step 'Set a name' do
                  category.name = category_name_3
                end
                step 'The "next" button is enabled' do
                  expect(category.button(:next)).to be_enabled
                end
              end

              purpose 'I cannot set a name of an existing category' do
                expect(category).to have_error_message_hidden(:name_already_in_use)
                category.name = category_name_1
                expect(category).to have_error_message_visible(:name_already_in_use)
              end
              purpose 'The name cannot be longer than 15 characters' do
                step 'Set a name of 16 characters' do
                  category.name = category_name_16_characters
                end
                step 'The name is clamped to 15 characters' do
                  expect(category.name).to eq(category_name_16_characters[0..14])
                end
              end
              category.name = category_name_3
              purpose 'The default weight is zero' do
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'I see a weight of 0%' do
                  expect(category.weighting_percent).to eq('0')
                  expect(category).to have_error_message_hidden(:weight_required)
                  expect(category).to have_error_message_hidden(:invalid_weight_range)
                end
              end
              purpose 'A weight is required' do
                step 'Set an empty weight' do
                  category.weighting_percent = ' '
                end
                step 'I see the message "Category weight is required"' do
                  expect(category).to have_error_message_visible(:weight_required)
                  expect(category).to have_error_message_hidden(:invalid_weight_range)
                end
                step 'The "next" button is disabled' do
                  expect(category.button(:next)).to be_disabled
                end
              end
              purpose 'The weight must be between 0 and 100' do
                step 'Set a weight of "-1"' do
                  category.weighting_percent = '-1'
                end
                step 'I do not see the message "Category weight must be between 0 and 100"' do
                  expect(category).to have_error_message_hidden(:weight_required)
                  expect(category).to have_error_message_visible(:invalid_weight_range)
                end
                step 'The "next" button is enabled' do
                  expect(category.button(:next)).to be_disabled
                end
                step 'Set a weight of "101"' do
                  category.weighting_percent = '101'
                end
                step 'I see the message "Category weight must be between 0 and 100"' do
                  expect(category).to have_error_message_hidden(:weight_required)
                  expect(category).to have_error_message_visible(:invalid_weight_range)
                end
                step 'The "next" button is disabled' do
                  expect(category.button(:next)).to be_disabled
                end
                step 'Set a weight of "50"' do
                  category.weighting_percent = '50'
                end
                step 'The "next" button is enabled' do
                  expect(category).to have_error_message_hidden(:weight_required)
                  expect(category).to have_error_message_hidden(:invalid_weight_range)
                  expect(category.button(:next)).to be_enabled
                end
              end
              purpose 'I can change the category grading' do
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'Select "Credit/no credit" option' do
                  category.credit_only = true
                end
                step 'Select "2" for the number of lowest grades dropped' do
                  category.drop_low_scores = '2'
                end
              end
              purpose 'I can change the number of attempts' do
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'Select "9" for the number of attempts' do
                  category.max_attempts = '9'
                end
              end
              purpose 'I can select the category strictness' do
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'Select "Accent marks will be taken into account."' do
                  category.take_accent_mark_into_account = true
                end
                step 'Select "Capitalization will be taken into account."' do
                  category.take_capitalization_into_account = true
                end
                step 'Select "Punctuation will be taken into account."' do
                  category.take_punctuation_into_account = true
                end
              end
              purpose 'I can change the enhanced feedback settings' do
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step "Select 'Don't provide students with enhanced feedback'" do
                  category.enhanced_feedback = false
                  expect(category).to have_enhanced_feedback_disable_warning
                  category.confirm_enhanced_feedback_disable
                end
              end
              purpose 'I can choose the category overdue policy' do
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'Select "Students cannot submit overdue/late assignments for credit."' do
                  category.accept_late_work = false
                  %i[none per_day flat].each do |type|
                    expect(category.page).to have_no_selector(
                      category.late_work_penalty_selector(type), visible: :visible
                    )
                  end
                end
                purpose 'Select "Students can submit overdue/late assignments for credit."' do
                  category.accept_late_work = true
                  step 'Select "No penalty"' do
                    category.late_work_penalty = :none
                  end
                  step 'I cannot see any input field' do
                    expect(category.page).to have_no_selector(
                      category.late_work_penalty_percent_selector, visible: :visible
                    )
                  end
                  step 'Select "% per day"' do
                    category.late_work_penalty = :per_day
                  end
                  step 'I can see an input field' do
                    expect(category.page).to have_selector(
                      category.late_work_penalty_percent_selector
                    )
                    expect(category.late_work_penalty_percent).to eq('5')
                    expect(category).to have_error_message_hidden(:late_work_penalty)
                    expect(category.button(:save)).to be_enabled
                  end
                  purpose 'The overdue submissions penalty must be between 0% and 100%' do
                    step 'Set an empty value' do
                      category.late_work_penalty_percent = ' '
                    end
                    step 'I see the message "A valid number is required."' do
                      expect(category).to have_error_message_visible(:late_work_penalty)
                    end
                    step 'The "save" button is disabled' do
                      expect(category.button(:save)).to be_disabled
                    end
                    step 'Set a value of 101%' do
                      category.late_work_penalty_percent = '101'
                    end
                    step 'I see the message "A valid number is required."' do
                      expect(category).to have_error_message_visible(:late_work_penalty)
                    end
                    step 'The "save" button is disabled' do
                      expect(category.button(:save)).to be_disabled
                    end
                    step 'Set a value of 5%' do
                      category.late_work_penalty_percent = '5'
                    end
                    step 'I do not see the message "A valid number is required."' do
                      expect(category).to have_error_message_hidden(:late_work_penalty)
                    end
                    step 'The "save" button is enabled' do
                      expect(category.button(:save)).to be_enabled
                    end
                  end
                end
                step 'Select "% (flat)"' do
                  category.late_work_penalty = :flat
                end
                step 'I can see an input field' do
                  expect(category.page).to have_selector(
                    category.late_work_penalty_percent_selector
                  )
                  category.late_work_penalty_percent = '10'
                end
              end

              purpose 'I can move forward and backward through the category creation procedure' do
                step 'click on the "back" button 6 times' do
                  6.times { category.button(:back).click }
                end
                step 'The name of the category is set' do
                  expect(category.name).to eq(category_name_3)
                end
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'The category weight is set' do
                  expect(category.weighting_percent).to eq('50')
                end
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'The category grading options are set' do
                  expect(category.credit_only).to be_truthy
                  expect(category.drop_low_scores).to eq('2')
                end
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'The number of attempts is set' do
                  expect(category.max_attempts).to eq('9')
                end
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'The category strictness options are set' do
                  expect(category.take_accent_mark_into_account).to be_truthy
                  expect(category.take_capitalization_into_account).to be_truthy
                  expect(category.take_punctuation_into_account).to be_truthy
                end
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'The enhanced feedback option is selected' do
                  expect(category.enhanced_feedback).to be_falsey
                end
                step 'Click the "next" button' do
                  category.button(:next).click
                end
                step 'The category overdue policy options are set' do
                  expect(category.accept_late_work).to be_truthy
                  expect(category.late_work_penalty).to eq(:flat)
                  expect(category.late_work_penalty_percent).to eq('10')
                end
              end
              step 'Click the "save" button' do
                category.button(:save).click
                expect(pobject).to have_no_add_category_modal
              end
            end
          end
          purpose 'I can edit a category' do
            step 'Click on the gear in the category control' do
              pobject.visit_category_contextual_menu(category_name_3, 'Edit Category')
            end
            step 'Click on "Edit category"'
            step 'I see a modal with the title "Edit Category"'
            with_element(pobject.edit_category_modal) do |category|
              purpose 'All the fields are already filled' do
                step 'The category name is set' do
                  expect(category.name).to eq(category_name_3)
                end
                step 'The weight is set' do
                  expect(category.weighting_percent).to eq('50')
                end
                step 'The maximum number of attempts is set' do
                  expect(category.max_attempts).to eq('9')
                end
                step 'The grading strictness options are selected' do
                  expect(category.take_accent_mark_into_account).to be_truthy
                  expect(category.take_capitalization_into_account).to be_truthy
                  expect(category.take_punctuation_into_account).to be_truthy
                end
                step 'The enhanced feedback option is selected' do
                  expect(category.enhanced_feedback).to be_falsey
                end
                step 'Click on the "Lateness" tab' do
                  category.select_tab(:lateness)
                end
                step 'The accept late work option is selected' do
                  expect(category.accept_late_work).to be_truthy
                end
                step 'The late work penalty option is selected' do
                  expect(category.late_work_penalty).to eq(:flat)
                end
                step 'The late work penalty percent is set' do
                  expect(category.late_work_penalty_percent).to eq('10')
                end
              end
              purpose 'I cannot set a name of an existing category' do
                step 'Set a name of an existing category' do
                  expect(category).to have_error_message_hidden(:name_already_in_use)
                  category.name = category_name_1
                end
                step 'I set the message "This category name is already in use"' do
                  expect(category).to have_error_message_visible(:name_already_in_use)
                end
              end
              purpose 'Category name cannot be longer than 15 characters' do
                step 'Set a name of 16 characters' do
                  category.name = category_name_16_characters
                end
                step 'The name is clamped to 15 characters' do
                  expect(category.name).to eq(category_name_16_characters[0..14])
                  category.name = category_name_3
                end
              end
              purpose 'Category weight is required' do
                step 'Set an empty weight' do
                  category.weighting_percent = ' '
                end
                step 'I see the message "Category weight is required"' do
                  expect(category).to have_error_message_visible(:weight_required)
                  expect(category).to have_error_message_hidden(:invalid_weight_range)
                end
                step 'The "done" button is disabled' do
                  expect(category.button(:done)).to be_disabled
                end
              end
              purpose 'the category weight must be between 0 and 100' do
                step 'Set a weight of "-1"' do
                  category.weighting_percent = '-1'
                end
                step 'I see the message "Category weight must be between 0 and 100"' do
                  expect(category).to have_error_message_hidden(:weight_required)
                  expect(category).to have_error_message_visible(:invalid_weight_range)
                end
                step 'The "done" button is disabled' do
                  expect(category.button(:done)).to be_disabled
                end
                step 'Set a weight of "101"' do
                  category.weighting_percent = '101'
                end
                step 'I see the message "Category weight must be between 0 and 100"' do
                  expect(category).to have_error_message_hidden(:weight_required)
                  expect(category).to have_error_message_visible(:invalid_weight_range)
                end
                step 'The "done" button is disabled' do
                  expect(category.button(:done)).to be_disabled
                end
                step 'Set a weight of "50"' do
                  category.weighting_percent = '50'
                end
                step 'I do not see the message "Category weight must be between 0 and 100"' do
                  expect(category).to have_error_message_hidden(:weight_required)
                  expect(category).to have_error_message_hidden(:invalid_weight_range)
                end
                step 'The "done" button is enabled' do
                  expect(category.button(:done)).to be_enabled
                end
              end
              purpose 'Grading settings can be changed' do
                category.select_tab(:grading)
                step 'Change the number of maximum attempts' do
                  category.max_attempts = '5'
                end
                step 'Invert the grading strictness options' do
                  category.credit_only = false
                  category.drop_low_scores = '3'
                end
                purpose 'I can change the grading strictness' do
                  category.take_accent_mark_into_account = false
                  category.take_capitalization_into_account = false
                  category.take_punctuation_into_account = false
                end
                step 'Invert the enhanced feedback option' do
                  category.enhanced_feedback = true
                end
              end

              purpose 'I can change the overdue policy' do
                category.select_tab(:lateness)
                purpose 'I can choose to accept late work' do
                  category.accept_late_work = true
                  category.late_work_penalty = :none
                  expect(category.page).to have_no_selector(
                    category.late_work_penalty_percent_selector, visible: :visible
                  )
                  category.late_work_penalty = :per_day
                  expect(category.page).to have_selector(
                    category.late_work_penalty_percent_selector
                  )
                  expect(category).to have_error_message_hidden(:late_work_penalty)
                  expect(category.button(:done)).to be_enabled

                  purpose 'The late work penalty must be between 0% and 100%' do
                    category.late_work_penalty_percent = ' '
                    expect(category).to have_error_message_visible(:late_work_penalty)
                    expect(category.button(:done)).to be_disabled
                    category.late_work_penalty_percent = '-1'
                    expect(category).to have_error_message_visible(:late_work_penalty)
                    expect(category.button(:done)).to be_disabled
                    category.late_work_penalty_percent = '101'
                    expect(category).to have_error_message_visible(:late_work_penalty)
                    expect(category.button(:done)).to be_disabled
                    category.late_work_penalty_percent = '5'
                    expect(category).to have_error_message_hidden(:late_work_penalty)
                    expect(category.button(:done)).to be_enabled
                  end
                end

                purpose 'I can choose to not accept late work' do
                  category.accept_late_work = false
                  %i[none per_day flat].each do |type|
                    expect(category.page).to have_no_selector(
                      category.late_work_penalty_selector(type), visible: :visible
                    )
                  end
                end
                step 'Click on the "done" button' do
                  category.button(:done).click
                  expect(pobject).to have_no_edit_category_modal
                end
              end
            end
            purpose 'My changes are saved' do
              pobject.visit_category_contextual_menu(category_name_3, 'Edit Category')
              with_element(pobject.edit_category_modal) do |category|
                category.select_tab(:lateness)
                expect(category.accept_late_work).to be_falsey
                category.select_tab(:grading)
                expect(category.name).to eq(category_name_3)
                expect(category.weighting_percent).to eq('50')
                expect(category.credit_only).to be_falsey
                expect(category.drop_low_scores).to eq('3')
                expect(category.max_attempts).to eq('5')
                expect(category.take_accent_mark_into_account).to be_falsey
                expect(category.take_capitalization_into_account).to be_falsey
                expect(category.take_punctuation_into_account).to be_falsey
                expect(category.enhanced_feedback).to be_truthy
                category.button(:done).click
                expect(pobject).to have_no_edit_category_modal
              end
            end
          end
          purpose 'I can delete a category' do
            step 'Click on the gear in the category control'
            step 'Click on "Delete category"'
            step 'I see the alert message "You are about delete this category. Are you Sure?"'
            step 'Accept the alert' do
              expect(accept_alert do
                pobject.visit_category_contextual_menu(category_name_2, 'Delete Category')
              end).to eq('You are about delete this category. Are you Sure?')
            end
          end
          step 'I am back to the gradebook categories tutorial'
          step 'Click on the "next" button' do
            pobject.button(:next).click
          end
        end
      end
      purpose 'The summary page' do
        with_element(SummaryPageObject.new(page)) do |pobject|
          step 'I see a summary of the course' do
            expect(pobject.start_date).to eq(start_date)
            expect(pobject.end_date).to eq(end_date)
            expect(pobject.first_unit).to eq(lessons[0].name)
            expect(pobject.last_unit).to eq(lessons[2].name)
            expect(pobject).to have_no_standard_sets
          end
          step 'I see a summary of all the categories' do
            with_element(pobject.category(0)) do |category|
              expect(category.name).to eq(category_name_1)
              expect(category.weight).to eq('50')
            end
            with_element(pobject.category(1)) do |category|
              expect(category.name).to eq(category_name_3)
              expect(category.weight).to eq('50')
            end
          end
          purpose 'I can generate PDF' do
            enable_headless_downloads do
              pobject.button(:generate_pdf).click
              wait_for_download
              expect(last_downloaded_file).to match(
                /course_summary_[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}/
              )
            end
          end
        end
      end

      purpose 'I can move forward and backward through the course setup' do
        step 'I can go back to the gradebook page' do
          with_element(SummaryPageObject.new(page)) do |pobject|
            pobject.button(:back).click
          end
        end
        step 'I can go back to the content page' do
          with_element(GradebookPageObject.new(page)) do |pobject|
            pobject.button(:back).click
          end
        end
        step 'I can go back to the course page' do
          with_element(ContentPageObject.new(page)) do |pobject|
            pobject.button(:back).click
          end
        end
        step 'I see the course page with all the fields correctly set' do
          with_element(CoursePageObject.new(page)) do |pobject|
            expect(pobject.course_name).to eq(course_name)
            expect(pobject.start_date).to eq(start_date)
            expect(pobject.end_date).to eq(end_date)
            step 'Click on the "next" button' do
              pobject.button(:next).click
            end
          end
        end

        step 'I see the content page with all the fields correctly set' do
          with_element(ContentPageObject.new(page)) do |pobject|
            expect(pobject.first_unit).to eq(lessons[0].unit_name)
            expect(pobject.last_unit).to eq(lessons[2].unit_name)
            expect(pobject.enable_vocab_tutorial_translations).to eq(true)
            expect(pobject.allow_review_requests).to eq(false)
            expect(pobject.allow_help_requests).to eq(false)
            expect(pobject.chat_availability).to eq(:always)
            expect(pobject.show_estimated_times).to eq(false)
            step 'Click on the "next" button' do
              expect(pobject.button(:next)).to be_disabled
              page.scroll_to(:bottom)
              expect(pobject.button(:next)).not_to be_disabled
              pobject.button(:next).click
            end
          end
        end

        step 'I see the gradebook page with all the fields correctly set' do
          with_element(GradebookPageObject.new(page)) do |pobject|
            expect(pobject.category_weighting_percent(category_name_1)).to eq('50')
            expect(pobject.category_weighting_percent(category_name_3)).to eq('50')
            step 'Click on the "next" button' do
              expect(pobject.button(:next)).not_to be_disabled
              pobject.button(:next).click
            end
          end
        end

        step 'I see the summary page with all the fields correctly set' do
          with_element(SummaryPageObject.new(page)) do |pobject|
            step 'I see a summary of the course' do
              expect(pobject.start_date).to eq(start_date)
              expect(pobject.end_date).to eq(end_date)
              expect(pobject.first_unit).to eq(lessons[0].name)
              expect(pobject.last_unit).to eq(lessons[2].name)
              expect(pobject).to have_no_standard_sets
            end

            step 'I see a summary of all the categories' do
              with_element(pobject.category(0)) do |category|
                expect(category.name).to eq(category_name_1)
                expect(category.weight).to eq('50')
              end
              with_element(pobject.category(1)) do |category|
                expect(category.name).to eq(category_name_3)
                expect(category.weight).to eq('50')
              end
            end
          end
        end
      end

      purpose 'After the course creation I am asked if I want to create a section' do
        step 'Click on the "save" button' do
          with_element(SummaryPageObject.new(page)) do |pobject|
            expect(pobject.button(:save)).to be_disabled
            page.scroll_to(:bottom)
            expect(pobject.button(:save)).not_to be_disabled
            pobject.button(:save).click
          end
        end
        step 'I see a modal with the message "Do you want to create a section for this course?"' do
          within(
            find('.test-section-modal', text: 'Do you want to create a section for this course?')
          ) do
            click_on('No')
          end
        end
        step 'Click on the "no" button'
      end

      purpose 'I see a success message when creating the course' do
        expect_flash_message(:notice, "Course #{course_name} was created successfully.")
      end
    end

    purpose 'I can edit a course' do
      purpose 'I can cancel at any time' do
        %i[course content gradebook summary].each do |tab|
          with_element(InstructorDashboardPageObject.new(page)) do |pobject|
            with_element(pobject.course_contextual_menu(course_name)) do |course_entry|
              course_entry.open_contextual_menu
              course_entry.edit_course
            end
          end

          select_edit_course_tab(tab).button(:cancel).click
        end
      end

      step 'Edit the course' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          with_element(pobject.course_contextual_menu(course_name)) do |course_entry|
            course_entry.open_contextual_menu
            course_entry.edit_course
          end
        end
      end

      purpose 'Information in the "Course" tab is set' do
        with_element(select_edit_course_tab(:course)) do |pobject|
          step 'Click on the "Course" tab'
          step 'The name is set' do
            expect(pobject.course_name).to eq(course_name)
          end
          step 'The start date is set' do
            expect(pobject.start_date).to eq(start_date)
          end
          step 'The end date is set' do
            expect(pobject.end_date).to eq(end_date)
          end
        end
      end
      purpose 'Information in the "Content" tab is set' do
        with_element(select_edit_course_tab(:content)) do |pobject|
          step 'Click on the "Content" tab'
          step 'The lesson range is set' do
            expect(pobject.first_unit).to eq(lessons[0].unit_name)
            expect(pobject.last_unit).to eq(lessons[2].unit_name)
          end
          step 'The access level is selected' do
          end
          step 'Technical support options are set' do
            expect(pobject.allow_review_requests).to eq(false)
            expect(pobject.chat_availability).to eq(:always)
          end
          step 'Chat availability option is set' do
            expect(pobject.chat_availability).to eq(:always)
          end
          step 'Estimated times visibility is set' do
            expect(pobject.show_estimated_times).to eq(false)
          end
        end
      end
      purpose 'Information in the "Gradebook" tab is set' do
        with_element(select_edit_course_tab(:gradebook)) do |pobject|
          step 'Click on the "Gradebook" tab'
          step 'The categories are displayed' do
            expect(pobject.category_weighting_percent(category_name_1)).to eq('50')
            expect(pobject.category_weighting_percent(category_name_3)).to eq('50')
          end
        end
      end
      purpose 'Information in the "Summary" tab is set' do
        with_element(select_edit_course_tab(:summary)) do |pobject|
          step 'I see a summary of the course' do
            expect(pobject.start_date).to eq(start_date)
            expect(pobject.end_date).to eq(end_date)
            expect(pobject.first_unit).to eq(lessons[0].name)
            expect(pobject.last_unit).to eq(lessons[2].name)
            expect(pobject).to have_no_standard_sets
          end

          step 'I see a summary of all the categories' do
            with_element(pobject.category(0)) do |category|
              expect(category.name).to eq(category_name_1)
              expect(category.weight).to eq('50')
            end
            with_element(pobject.category(1)) do |category|
              expect(category.name).to eq(category_name_3)
              expect(category.weight).to eq('50')
            end
          end
        end
      end

      purpose 'I can update all the course information' do
        purpose 'I can update the course information in the course tab' do
          with_element(select_edit_course_tab(:course)) do |pobject|
            step 'Set a new name' do
              pobject.course_name = course_name_edited
            end
            step 'Set a new start date' do
              pobject.start_date = start_date_edited
            end
            step 'Set a new end date' do
              pobject.end_date = end_date_edited
            end
            pobject.button(:save_changes).click
            expect(page).to have_selector(
              '.test-course-wizard-flash-notice', text: 'Successfully saved course settings.'
            )
          end
        end

        purpose 'I can update the course information in the content tab' do
          with_element(select_edit_course_tab(:content)) do |pobject|
            pobject.first_unit = lessons[0].unit_name
            pobject.last_unit = lessons[1].unit_name
            pobject.allow_review_requests = false
            pobject.allow_help_requests = false
            pobject.chat_availability = :never
            pobject.show_estimated_times = true
            pobject.button(:save_changes).click
            expect(page).to have_selector(
              '.test-course-wizard-flash-notice', text: 'Successfully saved course settings.'
            )
          end
        end

        purpose 'I can update the course information in the gradebook tab' do
          with_element(select_edit_course_tab(:gradebook)) do |pobject|
            pobject.change_category_weighting_percent(category_name_1, '50')
            pobject.change_category_weighting_percent(category_name_3, '50')
            pobject.button(:save_changes).click
            expect(page).to have_selector(
              '.test-course-wizard-flash-notice', text: 'Successfully saved course settings.'
            )
          end
        end

        purpose 'I see the updated information in the summary tab' do
          with_element(select_edit_course_tab(:summary)) do |pobject|
            # There is nothing to change on this tab. Just check the save button
            step 'The information are updated'

            step 'I see success message when I save my changes' do
              pobject.button(:save_changes).click

              expect(page).to have_selector(
                '.test-course-wizard-flash-notice',
                text: 'Successfully saved course settings.'
              )
            end
          end
        end

        step 'I exit the edit mode' do
          with_element(select_edit_course_tab(:summary)) do |pobject|
            pobject.button(:cancel).click
          end
        end
      end

      purpose 'Updated information have been saved' do
        step 'Edit the course' do
          with_element(InstructorDashboardPageObject.new(page)) do |pobject|
            with_element(pobject.course_contextual_menu(course_name_edited)) do |course_entry|
              course_entry.open_contextual_menu
              course_entry.edit_course
            end
          end
        end

        step 'Click on the "Course" tab' do
          with_element(select_edit_course_tab(:course)) do |pobject|
            step 'All the information is set' do
              expect(pobject.course_name).to eq(course_name_edited)
              expect(pobject.start_date).to eq(start_date_edited)
              expect(pobject.end_date).to eq(end_date_edited)
            end
          end
        end
        step 'Click on the "Content" tab' do
          with_element(select_edit_course_tab(:content)) do |pobject|
            step 'All the information is set' do
              expect(pobject.first_unit).to eq(lessons[0].unit_name)
              expect(pobject.last_unit).to eq(lessons[1].unit_name)
              expect(pobject.allow_review_requests).to be_falsey
              expect(pobject.allow_help_requests).to be_falsey
              expect(pobject.chat_availability).to eq(:never)
              expect(pobject.show_estimated_times).to be_truthy
            end
          end
        end
        step 'Click on the "Gradebook" tab' do
          with_element(select_edit_course_tab(:gradebook)) do |pobject|
            step 'All the information is set' do
              expect(pobject.category_weighting_percent(category_name_1)).to eq('50')
              expect(pobject.category_weighting_percent(category_name_3)).to eq('50')
            end
          end
        end
        step 'Click on the "Summary" tab' do
          with_element(select_edit_course_tab(:summary)) do |pobject|
            step 'I see a summary of the course' do
              expect(pobject.start_date).to eq(start_date)
              expect(pobject.end_date).to eq(end_date_edited)
              expect(pobject.first_unit).to eq(lessons[0].name)
              expect(pobject.last_unit).to eq(lessons[1].name)
              expect(pobject).to have_no_standard_sets
            end

            step 'I see a summary of all the categories' do
              with_element(pobject.category(0)) do |category|
                expect(category.name).to eq(category_name_1)
                expect(category.weight).to eq('50')
              end
              with_element(pobject.category(1)) do |category|
                expect(category.name).to eq(category_name_3)
                expect(category.weight).to eq('50')
              end
            end

            step 'Click on the "cancel" button' do
              pobject.button(:cancel).click
            end
          end
        end
      end
    end

    purpose 'I can delete a course' do
      purpose 'I cannot delete a section that contains a course' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          step 'Add a section to the course'
          step 'Click on the gear of the course'
          step 'The "Delete Course" link is disabled'
          # when a section contains a course the delete form does not exist.
          expect(
            pobject.course_contextual_menu_entry(existing_course.name, 'Delete Course')
          ).to have_no_selector('form')

          # when a section contains a course the delete form does exist.
          expect(pobject.course_contextual_menu_entry(course_name_edited, 'Delete Course'))
            .to have_selector('form')
        end
      end

      purpose 'I can cancel when asking for confirmation' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          with_element(pobject.course_contextual_menu(course_name_edited)) do |course_entry|
            course_entry.open_contextual_menu
            course_entry.delete_course

            step 'I see the modal and cancel' do
              page.within('.c-modal.js-delete-dialog') do
                click_button('Cancel')
              end
            end
            # When choosing 'cancel', the contextual menu is not closed
            course_entry.close_contextual_menu
          end
        end
      end

      purpose 'I see a success message when deleting the course' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          with_element(pobject.course_contextual_menu(course_name_edited)) do |course_entry|
            course_entry.open_contextual_menu
            course_entry.delete_course

            step 'I see the modal and confirm' do
              page.within('.c-modal.js-delete-dialog') do
                click_button('Confirm')
              end
            end
          end
        end

        expect_flash_message(:notice, "Course #{course_name_edited} was deleted successfully.")
      end
    end
  end

  context 'when the school has disabled chat support,' do
    before do
      create(:school_config, school:, chat_support_disabled: true)
    end

    # NOTE: This scenario only checks the chat option.
    # All the other validations are covered by another scenario.
    scenario 'As an instructor, I cannot enable chat support when creating and editing a course' do
      visit instructor_dashboard_path(program)

      purpose 'I go to the advanced setup course creation page' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          pobject.button(:add_course).click
          wait_for_ajax
        end

        with_element(CourseSetupPathPageObject.new(page)) do |pobject|
          pobject.button(:advanced_setup).click
          wait_for_ajax
        end
      end

      purpose 'The course page' do
        with_element(CoursePageObject.new(page)) do |pobject|
          pobject.course_name = course_name
          pobject.start_date = start_date
          pobject.end_date = end_date

          pobject.button(:next).click
          wait_for_ajax
        end
      end

      purpose 'The content page' do
        with_element(ContentPageObject.new(page)) do |pobject|
          select 'Default settings', from: 'previous_course_id'

          pobject.first_unit = lessons[1].unit_name
          pobject.last_unit = lessons[2].unit_name

          purpose 'The chat feature is disabled' do
            expect(pobject).to have_chat_feature_disabled
          end

          page.scroll_to(:bottom)
          pobject.button(:next).click
        end
      end

      purpose 'The gradebook page' do
        with_element(GradebookPageObject.new(page)) do |pobject|
          select 'Basic course', from: 'previous_course_id'

          # Capybara is not calculating the body.offsetHeight when the tutorial
          # expander is contracted, causing a display issue and JS issues.
          # So we expand it.
          page.find('.expander__button').click
          page.scroll_to(:bottom)
          pobject.button(:next).click
        end
      end

      purpose 'The summary page' do
        with_element(SummaryPageObject.new(page)) do |pobject|
          step 'I see a summary of the course' do
            expect(pobject.start_date).to eq(start_date)
            expect(pobject.end_date).to eq(end_date)
            expect(pobject.first_unit).to eq(lessons[1].name)
            expect(pobject.last_unit).to eq(lessons[2].name)
          end

          page.scroll_to(:bottom)
          pobject.button(:save).click
        end
      end

      purpose 'I do not create any section' do
        within(
          find('.test-section-modal', text: 'Do you want to create a section for this course?')
        ) do
          click_on('No')
        end
      end

      step 'I see a success flash message' do
        expect_flash_message(:notice, "Course #{course_name} was created successfully.")
      end

      purpose 'The changes are saved in the database' do
        course = Course.last

        expect(course).to have_attributes(
          name: course_name,
          chat_level: 'disabled'
        )

        # We manually enable the chat level in order to check that when we edit
        # the course, the chat level is set back to disabled.
        course.update!(chat_level: 'partner_chat')
      end

      purpose 'I can edit a course' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          with_element(pobject.course_contextual_menu(course_name)) do |course_entry|
            course_entry.open_contextual_menu
            course_entry.edit_course
          end
        end

        purpose 'Information in the "Content" tab is set' do
          with_element(select_edit_course_tab(:content)) do |pobject|
            purpose 'The chat feature is disabled' do
              expect(pobject).to have_chat_feature_disabled
            end
          end
        end

        purpose 'I can save my changes' do
          expect do
            with_element(select_edit_course_tab(:content)) do |pobject|
              pobject.button(:save_changes).click

              expect(page).to have_selector(
                '.test-course-wizard-flash-notice', text: 'Successfully saved course settings.'
              )
            end
          end.not_to change(Course, :count)
        end

        purpose 'The changes are saved in the database' do
          expect(Course.last).to have_attributes(
            name: course_name,
            chat_level: 'disabled'
          )
        end
      end
    end
  end

  context 'when the program supports standard sets,' do
    let(:program) do
      create(:program).tap do |program|
        program.units = Array.new(3) do |index|
          name = "Leccion #{index + 1}"
          create(:unit_with_lesson_with_toc_entries, name: name, label: name, program: program)
        end
      end
    end
    let(:standard_set_group_name_1) { 'standard group 1' }
    let(:standard_set_group_name_2) { 'standard group 2' }
    let(:standard_set_group_name_3) { "#{standard_set_4.issuer} - #{standard_set_4.name}" }
    let(:standard_set_1) { create(:standard_set, display_name: standard_set_group_name_1) }
    let(:standard_set_2) { create(:standard_set, display_name: standard_set_group_name_1) }
    let(:standard_set_3) { create(:standard_set, display_name: standard_set_group_name_2) }
    let(:standard_set_4) { create(:standard_set, display_name: '', issuer: 'Issuer', name: 'Standard Set') }

    before do
      create(
        :program_config_with_standard_sets,
        program: program,
        supported_standard_sets: [standard_set_1, standard_set_2, standard_set_3, standard_set_4]
      )
      existing_course.reload.update!(standard_sets: [standard_set_1, standard_set_4])
    end

    # NOTE: This scenario only checks the standard sets selection and saving.
    # All the other validations are covered by the scenario when the program does
    # not support standard sets.
    scenario 'As an instructor, I can create a course using the advanced course setup' do
      visit instructor_dashboard_path(program)

      purpose 'I go to the advanced setup course creation page' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          pobject.button(:add_course).click
          wait_for_ajax
        end
      end

      purpose 'The course page' do
        with_element(CoursePageObject.new(page)) do |pobject|
          pobject.course_name = course_name
          pobject.start_date = start_date
          pobject.end_date = end_date

          pobject.button(:next).click
          wait_for_ajax
        end
      end

      purpose 'The content page' do
        with_element(ContentPageObject.new(page)) do |pobject|
          select 'Default settings', from: 'previous_course_id'

          purpose 'All standard sets are grouped by name and selected by default' do
            expect(pobject.standard_sets).to contain_exactly(
              an_object_having_attributes(
                name: standard_set_group_name_1,
                checked?: true
              ),
              an_object_having_attributes(
                name: standard_set_group_name_2,
                checked?: true
              ),
              an_object_having_attributes(
                name: standard_set_group_name_3,
                checked?: true
              )
            )
          end

          purpose 'All standard sets are ordered alphabetically' do
            expect(pobject.standard_sets.map(&:name)).to eq(
              [
                standard_set_group_name_3,
                standard_set_group_name_1,
                standard_set_group_name_2
              ]
            )
          end

          purpose 'When I select the settings from an existing course, I see ' \
                  'the standards of the other course selected' do
            select existing_course.name, from: 'previous_course_id'

            expect(pobject.standard_sets).to contain_exactly(
              an_object_having_attributes(
                name: standard_set_group_name_1,
                checked?: true
              ),
              an_object_having_attributes(
                name: standard_set_group_name_2,
                checked?: false
              ),
              an_object_having_attributes(
                name: standard_set_group_name_3,
                checked?: true
              )
            )
          end

          purpose 'I see an error message when I do not select any standard' do
            pobject.standard_sets.each(&:uncheck)

            expect(pobject).to have_standard_sets_error_message_visible
          end

          purpose 'I do not see any error message when I select at least one standard' do
            pobject.standard_set(standard_set_group_name_1).check

            expect(pobject).to have_standard_sets_error_message_hidden
          end

          pobject.first_unit = lessons[1].unit_name
          pobject.last_unit = lessons[2].unit_name

          page.scroll_to(:bottom)
          pobject.button(:next).click
        end
      end

      purpose 'The gradebook page' do
        with_element(GradebookPageObject.new(page)) do |pobject|
          select 'Basic course', from: 'previous_course_id'

          # Capybara is not calculating the body.offsetHeight when the tutorial
          # expander is contracted, causing a display issue and JS issues.
          # So we expand it.
          page.find('.expander__button').click
          step 'I see the categories from the Basic course' do
            # This step is needed to be sure the animation due to the course
            # selection is complete
            expect(pobject.category_weighting_percent('Homework')).to eq('100')
          end

          # Wait for the next button to be enabled
          page.scroll_to(:bottom)
          Waiter.new.wait do
            pobject.button(:next).enabled?
          end

          pobject.button(:next).click
        end
      end

      purpose 'The summary page' do
        with_element(SummaryPageObject.new(page)) do |pobject|
          step 'I see a summary of the course' do
            expect(pobject.start_date).to eq(start_date)
            expect(pobject.end_date).to eq(end_date)
            expect(pobject.first_unit).to eq(lessons[1].name)
            expect(pobject.last_unit).to eq(lessons[2].name)
            expect(pobject.standard_sets).to eq(
              [standard_set_group_name_1]
            )
          end

          page.scroll_to(:bottom)
          pobject.button(:save).click
        end
      end

      purpose 'I do not create any section' do
        within(
          find('.test-section-modal', text: 'Do you want to create a section for this course?')
        ) do
          click_on('No')
        end
      end

      step 'I see a success flash message' do
        expect_flash_message(:notice, "Course #{course_name} was created successfully.")
      end

      purpose 'The changes are saved in the database' do
        course = Course.last

        expect(course).to have_attributes(
          name: course_name,
          standard_set_ids: [standard_set_1.id, standard_set_2.id]
        )
      end

      purpose 'I can edit a course' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          with_element(pobject.course_contextual_menu(course_name)) do |course_entry|
            course_entry.open_contextual_menu
            course_entry.edit_course
          end
        end

        purpose 'Information in the "Course" tab is set' do
          with_element(select_edit_course_tab(:course)) do |pobject|
            expect(pobject.course_name).to eq(course_name)
            expect(pobject.start_date).to eq(start_date)
            expect(pobject.end_date).to eq(end_date)
          end
        end

        purpose 'Information in the "Content" tab is set' do
          with_element(select_edit_course_tab(:content)) do |pobject|
            purpose 'Course standard sets are selected' do
              expect(pobject.standard_sets).to contain_exactly(
                an_object_having_attributes(
                  name: standard_set_group_name_1,
                  checked?: true
                ),
                an_object_having_attributes(
                  name: standard_set_group_name_2,
                  checked?: false
                ),
                an_object_having_attributes(
                  name: standard_set_group_name_3,
                  checked?: false
                )
              )
            end

            purpose 'All standard sets are ordered alphabetically' do
              expect(pobject.standard_sets.map(&:name)).to eq(
                [
                  standard_set_group_name_3,
                  standard_set_group_name_1,
                  standard_set_group_name_2
                ]
              )
            end

            purpose 'I see an error message when I do not select any standard' do
              pobject.standard_set(standard_set_group_name_1).uncheck

              expect(pobject).to have_standard_sets_error_message_visible
            end

            purpose 'I do not see any error message when I select at least one standard' do
              pobject.standard_set(standard_set_group_name_2).check

              expect(pobject).to have_standard_sets_error_message_hidden
            end

            pobject.standard_set(standard_set_group_name_3).check
          end
        end

        purpose 'Information in the summary tab is set' do
          with_element(select_edit_course_tab(:summary)) do |pobject|
            expect(pobject.start_date).to eq(start_date)
            expect(pobject.end_date).to eq(end_date)
            expect(pobject.first_unit).to eq(lessons[1].name)
            expect(pobject.last_unit).to eq(lessons[2].name)

            purpose 'All selected standard sets are ordered alphabetically' do
              expect(pobject.standard_sets).to eq(
                [
                  standard_set_group_name_3,
                  standard_set_group_name_2
                ]
              )
            end
          end
        end

        purpose 'I can save my changes' do
          expect do
            with_element(select_edit_course_tab(:content)) do |pobject|
              pobject.button(:save_changes).click

              expect(page).to have_selector(
                '.test-course-wizard-flash-notice', text: 'Successfully saved course settings.'
              )
            end
          end.not_to change(Course, :count)
        end

        purpose 'The changes are saved in the database' do
          expect(Course.last).to have_attributes(
            name: course_name,
            standard_set_ids: [standard_set_3.id, standard_set_4.id]
          )
        end
      end
    end
  end

  context 'with a LTI linked section,' do
    let(:lti_school) { create(:school) }
    let(:lti_platform) { create(:lti_rostering_platform, school: lti_school) }
    let(:lti_instructor) do
      create(:lti_rostering_instructor, schools: [lti_school]).tap do |instructor|
        create(:lti_rostering_user_link, user: instructor, lti_platform: lti_platform)
      end
    end
    let(:lti_course) do
      create(
        :course,
        name: course_name_76_characters,
        program: program,
        school_id: lti_platform.school_id,
        owner: lti_instructor,
        first_unit: lessons.first.unit,
        last_unit: lessons.last.unit
      ).tap do |course|
        course.categories << create(:category, course: course, weighting_percent: 100)
      end
    end
    let(:lti_section) { create(:section, course: lti_course, instructor: lti_instructor) }

    before do
      create(:lti_context_link, lti_platform: lti_platform, section: lti_section)
      initialize_program_access_client_calls_for_instructor(lti_instructor, program)
      course_packages_by_course[lti_course.guid] = [course_package]
    end

    scenario 'As an LTi instructor, I can edit the course name with no restriction' do
      step 'I have a course that has a linked LTI section' do
        log_in_as(lti_instructor)
      end
      step 'Visit the course edit page' do
        visit edit_instructor_course_path(program, lti_course)
      end

      purpose 'I cannot edit the course name' do
        with_element(ExpressCourseSetupPageObject.new(page)) do |pobject|
          course_name_container = page.find(pobject.course_name_selector)
          step 'The course name is set' do
            expect(page).to have_selector(pobject.course_name_selector, visible: :visible)
            expect(pobject.course_name).to eq(course_name_76_characters)
            expect(course_name_container['readonly']).to eq 'true'
          end

          step 'I do not see any error message due to the course name length greater than 75 characters' do
            expect(pobject).not_to have_error_message_visible(:course_name_length)
          end
        end
      end
    end
  end

  context 'As a RA instructor,' do
    before do
      create(
        :one_roster_linked_section,
        section: existing_section,
        academic_session: 'abc'
      )
    end

    scenario 'I can edit a one roster linked course' do
      step 'Visit the course edit page' do
        visit edit_instructor_course_path(program, existing_course)
      end

      purpose 'I cannot edit the course name' do
        wait_for_ajax
        with_element(ExpressCourseSetupPageObject.new(page)) do |pobject|
          course_name_container = page.find(pobject.course_name_selector)
          expect(course_name_container['readonly']).to eq 'true'
        end
      end

      purpose 'I cannot edit the start and end dates' do
        with_element(ExpressCourseSetupPageObject.new(page)) do |pobject|
          start_date_input = page.find(pobject.start_date_selector)
          expect(start_date_input['disabled']).to eq 'true'
          end_date_input = page.find(pobject.end_date_selector)
          expect(end_date_input['disabled']).to eq 'true'
        end
      end
    end

    scenario 'I can edit a one roster linked section' do
      allow(Maestro::School).to receive(:instructors).and_return({})

      step 'Visit the section edit page' do
        visit edit_instructor_course_section_path(program, existing_course, existing_section)
      end

      purpose 'I cannot edit the section name' do
        section_name_container = page.find('.test-section-name')
        expect(section_name_container['readonly']).to eq 'true'
      end

      purpose 'I cannot see the allow students to enroll option' do
        with_element(ExpressCourseSetupPageObject.new(page)) do |pobject|
          expect(page).not_to have_selector(pobject.allow_student_enrollment_selector)
        end
      end

      purpose 'I cannot see the add co-instructor form' do
        with_element(ExpressCourseSetupPageObject.new(page)) do |pobject|
          expect(page).not_to have_selector(pobject.co_instructor_form_selector)
        end
      end
    end
  end

  def select_edit_course_tab(tab)
    name, klass = case tab
                  when :course then ['Course', CoursePageObject]
                  when :content then ['Content', ContentPageObject]
                  when :gradebook then ['Gradebook', GradebookPageObject]
                  when :summary then ['Summary', SummaryPageObject]
                  else raise ArgumentError, "invalid tab '#{tab}'"
                  end
    find('.test-edit-course-tab a', text: name).click
    klass.new(page)
  end
end
