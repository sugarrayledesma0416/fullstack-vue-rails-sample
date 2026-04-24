feature 'Express Course setup wizard', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include GradebookEngineHelpers

  let(:school) { create(:school) }
  let(:program) do
    create(:vol_program).tap do |program|
      program.units = Array.new(6) do |index|
        name = "Leccion #{index + 1}"
        create(:unit_with_lesson_with_toc_entries, name: name, label: name, program: program)
      end
    end
  end
  let(:lessons) { program.units.flat_map(&:lessons) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }
  let(:activities) do
    lessons.map.with_index do |lesson, lesson_index|
      create(
        :activity,
        activity_location_attributes(
          program, strand_id: lesson.strands.first.location, lesson: lesson
        ).merge(
          license_group_id: SectionLearningTrack::DEFAULT_LICENSE_GROUP_IDS.first,
          minutes_to_complete: 35
        )
      ).tap do |activity|
        # Need to assign these activities for the course and section to appear in the learning tracks
        create(
          :assignment,
          assignable: activity,
          due_date: (lesson_index.odd? ? 4.days.from_now : 5.days.from_now).to_date,
          section: existing_section,
          show_at: 1.day.ago
        )
      end
    end
  end
  # activities included in the essentials learning track
  let(:essentials_activities) { activities[0..2] }

  let(:activity_hash) do
    activities.to_h do |activity|
      [
        activity.id.to_s,
        {
          activity_requirements: {
            require_microphone: activity.chat_or_recording?,
            require_partner: activity.partner_chat?,
            instructor_graded: activity.instructor_graded?
          },
          activity_type: Activity.humanize_activity_type(activity.activity_type),
          id: activity.id,
          lesson_name: activity.lesson.name,
          minutes_to_complete: activity.minutes_to_complete,
          strand: activity.concept.base_name,
          strand_name: 'Blah',
          substrand: '',
          title: activity.title,
          unit_id: activity.lesson.unit.id
        }
      ]
    end
  end

  let(:group_set) { create(:group_set, name: 'Learn Groups') }
  let(:track_group) do
    create(
      :track_group,
      program: program,
      name: 'Learn',
      group_set: group_set,
      concept: activities.first.concept,
      lesson: lesson
    )
  end

  let(:s3_bucket) { instance_double(Radner::S3Storage) }
  let(:course_package) do
    Maestro::CoursePackage.new(
      content_type: 'level',
      id: 1,
      name: 'Supersite'
    )
  end
  let(:course_package_1) do
    instance_double(
      Maestro::CoursePackage,
      content_type: 'level',
      id: 123,
      program_id: program.id,
      name: 'Supersite',
      rank: 1,
      response: { 'id' => 123, 'name' => 'Supersite' }
    )
  end
  let(:course_package_2) do
    instance_double(
      Maestro::CoursePackage,
      content_type: 'level',
      id: 456,
      program_id: program.id,
      name: 'Portails 2',
      rank: 1,
      response: { 'id' => 456, 'name' => 'Portails 2' }
    )
  end

  let(:learning_tracks_response) do
    {
      tracks: {
        'Fully Online': {
          subtracks: {
            Complete: {
              activities: activities.map do |activity|
                {
                  id: activity.id,
                  group: track_group.name,
                  group_id: track_group.id,
                  category: existing_course.categories.first.name
                }
              end,
              strands: activities.map(&:concept).map(&:base_name),
              categories: 'Base Categories',
              first_unit_id: program.units.first.id,
              last_unit_id: program.units.last.id,
              rank: 1,
              units: program.units.map(&:attributes)
            },
            Essentials: {
              activities: activities.map do |activity|
                {
                  id: activity.id,
                  group: track_group.name,
                  group_id: track_group.id,
                  category: existing_course.categories.first.name
                }
              end,
              strands: essentials_activities.map(&:concept).map(&:base_name),
              categories: 'Base Categories',
              first_unit_id: program.units.first.id,
              last_unit_id: program.units.last.id,
              rank: 1,
              units: program.units.map(&:attributes)
            }
          }
        }
      },
      activities: activity_hash,
      strands: {
        Contextos: { name: 'Contextos', color: 'blue', unit_ids: program.units.map(&:id) },
        Fotonovela: { name: 'Fotonovela', color: 'red', unit_ids: [program.units.second.id] },
        Estructura: { name: 'Estructura', color: 'green', unit_ids: program.units.map(&:id) },
        Panorama: { name: 'Panorama', color: 'orange', unit_ids: program.units.map(&:id) },
        Pronuncuacion: { name: 'Pronuncuacion', color: 'yellow', unit_ids: program.units.map(&:id) },
        Vocabulario: { name: 'Vocabulario', color: 'pink', unit_ids: [] }
      },
      categories: {
        'Base Categories' => existing_course.categories.to_h do |category|
          [
            category.name,
            {
              accept_late_work: category.accept_late_work,
              credit_only: category.credit_only,
              late_work_penalty: category.late_work_penalty,
              max_attempts: category.max_attempts,
              name: category.name,
              penalty_percent: category.penalty_percent,
              rank: category.rank,
              weighting_percent: category.weighting_percent
            }
          ]
        end
      }
    }
  end
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
  let(:existing_section) { create(:section, course: existing_course, instructor: instructor) }
  let(:course_name) { 'My express course' }
  let(:course_name_30_characters) { '012345678901234567890123456789' }
  let(:course_name_31_characters) { '0123456789012345678901234567890' }
  let(:section_name) { 'section name' }
  let(:section_name_75_characters) { '111111111122222222223333333333444444444455555555556666666666777777777788888' }
  let(:section_name_76_characters) { '1111111111222222222233333333334444444444555555555566666666667777777777888888' }
  let(:start_date) { Time.zone.today }
  let(:end_date) { 2.weeks.from_now.to_date }
  let(:incorrect_end_date) { (Time.zone.today - 1.day).to_date }

  around do |example|
    # Freeze the time to ease the testing of the due dates.
    # Because this does not freeze the time used by the javascript code, it must
    # be a future time to pass the course start date validation.
    Timecop.freeze(Time.local(2032, 3, 31, 10, 5)) do
      example.run
    end
  end

  before do
    # Mock Maestro::Client API calls
    initialize_program_access_client_calls_for_instructor(instructor, program)
    allow(Maestro::CourseLicense).to receive(:all).and_return(
      [
        Maestro::CourseLicense.new(
          'license_group' => { 'id' => 1, 'demo' => false }
        )
      ]
    )
    allow(Maestro::CoursePackage).to receive(:all).and_return([])
    allow(Maestro::CoursePackage).to receive(:available_packages)
      .and_return([course_package.response])
    allow(Maestro::CoursePackage).to receive(:all_for_courses)
      .with([existing_course.guid])
      .and_return(existing_course.guid => [course_package_1, course_package_2])
    allow(Maestro::CoursePackage).to receive(:all_for_course)
      .and_return([course_package])
    allow(CourseLicenseCreatorWorker).to receive(:perform_async)
    allow(Maestro::UserLicense).to receive(
      :all_for_user_and_program
    ).with([], program.id).and_return([])
    allow(Maestro::CourseLicense).to receive(:create)

    # Set up program config
    create(:vol_program_config, program: program)

    # Mock S3 API calls to retrieve learning tracks
    allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
    allow(s3_bucket).to receive(:fetch).and_return(learning_tracks_response)
    allow(s3_bucket).to receive(:directory_files).and_return([])
    allow(LearningTrack::ActivityExporter).to receive(:activities_json)

    log_in_as(instructor)
  end

  scenario 'As an instructor, I can create a course using the express course ' \
           'setup without assigning any assignments', nondeterministic: true do
    step 'Visit the dashboard page' do
      visit instructor_dashboard_path(program)
    end

    step 'Click on "Add course"' do
      with_element(InstructorDashboardPageObject.new(page)) do |pobject|
        pobject.button(:add_course).click
        wait_for_ajax
      end
    end

    step 'Select "Express setup"' do
      with_element(CourseSetupPathPageObject.new(page)) do |pobject|
        pobject.button(:express_setup).click
        wait_for_ajax
      end
    end

    purpose 'I can go back to the course setup option page' do
      step 'Click on the "back" button' do
        with_element(ExpressCourseSetupPageObject.new(page)) do |pobject|
          pobject.button(:back).click
          wait_for_ajax
        end
      end

      step 'I am on the course setup option page' do
        expect(page).to have_selector('h1', text: 'Course Setup')
      end
    end

    purpose 'I can cancel the course creation' do
      step 'I Select "Express setup"' do
        with_element(CourseSetupPathPageObject.new(page)) do |pobject|
          pobject.button(:express_setup).click
          wait_for_ajax
        end
      end

      step 'I cancel the course creation' do
        with_element(ExpressCourseSetupPageObject.new(page)) do |pobject|
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

      step 'I select "Express setup"' do
        with_element(CourseSetupPathPageObject.new(page)) do |pobject|
          pobject.button(:express_setup).click
          wait_for_ajax
        end
      end

      with_element(ExpressCourseSetupPageObject.new(page)) do |pobject|
        step 'Set a course name' do
          pobject.course_name = course_name
        end

        step 'I see an alert when I cancel' do
          expect(accept_alert do
            pobject.button(:cancel).click
          end).to eq('')
        end
      end

      step 'I am back to the dashboard' do
        expect(page).to have_current_path(instructor_dashboard_path(program))
      end
    end

    purpose 'I create a course' do
      step 'I click on "Add course"' do
        with_element(InstructorDashboardPageObject.new(page)) do |pobject|
          pobject.button(:add_course).click
          wait_for_ajax
        end
      end

      step 'Select "Express setup"' do
        with_element(CourseSetupPathPageObject.new(page)) do |pobject|
          pobject.button(:express_setup).click
          wait_for_ajax
        end
      end

      with_element(ExpressCourseSetupPageObject.new(page)) do |pobject|
        purpose 'A course name and a section name are required' do
          step 'The "next" button is disabled' do
            expect(pobject.button(:next)).to be_disabled
          end
          step 'Set a course name' do
            pobject.course_name = course_name
          end
          step 'The "next" button is disabled' do
            expect(pobject.button(:next)).to be_disabled
            expect(pobject).to have_error_message_hidden(:course_name_required)
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
          step 'Set a Section name' do
            pobject.sections.first.name = section_name
          end
          step 'The "next" button is enabled' do
            expect(pobject.button(:next)).not_to be_disabled
          end
        end

        purpose 'Course name cannot be longer than 30 characters' do
          step 'Set a course name of 30 characters' do
            pobject.course_name = course_name_30_characters
          end
          step 'The "next" button is enabled' do
            expect(pobject).to have_error_message_hidden(:course_name_length)
            expect(pobject.button(:next)).not_to be_disabled
          end
          step 'Set a course name of 31 characters' do
            pobject.course_name = course_name_31_characters
          end
          step 'I see the message "Your course name cannot be longer than 30 characters."' do
            expect(pobject).to have_error_message_visible(:course_name_length)
          end
          step 'The "next" button is disabled' do
            expect(pobject.button(:next)).to be_disabled
          end
          step 'Set a valid course name' do
            pobject.course_name = course_name
          end
        end

        purpose 'Section name cannot be longer than 75 characters' do
          step 'Set a section name of 75 characters' do
            pobject.sections.first.name = section_name_75_characters
          end
          step 'The "next" button is enabled' do
            expect(pobject).to have_error_message_hidden(:section_name_length)
            expect(pobject.button(:next)).not_to be_disabled
          end
          step 'Set a section name of 76 characters' do
            pobject.sections.first.name = section_name_76_characters
          end
          step 'I see the message "Your section name cannot be longer than 75 characters.' do
            expect(pobject).to have_error_message_visible(:section_name_length)
          end
          step 'The "next" button is disabled' do
            expect(pobject.button(:next)).to be_disabled
          end
          step 'Set a valid section name' do
            pobject.sections.first.name = section_name
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

        purpose 'I can create up to 10 sections' do
          step 'Select 10 sections in the dropdown' do
            pobject.number_of_sections = 10
          end
          step 'I see 10 section name input fields' do
            expect(pobject.sections.size).to eq(10)
          end
          step 'The "next" button is disabled' do
            expect(pobject.button(:next)).to be_disabled
          end
          step 'Set the 10 section names' do
            pobject.sections.each.with_index(1) do |section, i|
              section.name = "section #{i}"
            end
          end
          step 'The "next" button is enabled' do
            expect(pobject.button(:next)).not_to be_disabled
          end
        end

        purpose 'I can decrease the number of section without loosing their name' do
          step 'Select 5 sections in the dropdown' do
            pobject.number_of_sections = 5
          end
          step 'I see 5 section name input fields' do
            expect(pobject.sections.size).to eq(5)
          end
          step 'The input fields did not lose their content' do
            pobject.sections.each.with_index(1) do |section, i|
              expect(section.name).to eq("section #{i}")
            end
          end
          step 'The "next" button is enabled' do
            expect(pobject.button(:next)).not_to be_disabled
          end
          step 'Select 2 sections in the dropdown' do
            pobject.number_of_sections = 2
          end
        end

        purpose 'I can see a preview of the information seen by students when enrolling' do
          with_element(pobject.preview_as_student) do |preview|
            preview.show

            expect(preview.caption).to eq(
              'This is a preview of the information seen by students when enrolling.'
            )

            expect(preview.sections).to match(
              [
                an_object_having_attributes(
                  instructor: instructor.last_name,
                  course: course_name,
                  section: 'section 1'
                ),
                an_object_having_attributes(
                  instructor: instructor.last_name,
                  course: course_name,
                  section: 'section 2'
                )
              ]
            )

            expect(preview.previous_sections).to match(
              [
                an_object_having_attributes(
                  instructor: "#{existing_section.instructor.last_name}, " \
                              "#{existing_section.instructor.first_name}",
                  # course name is truncated to 18 characters followed by 3 dots.
                  course: "#{existing_course.name[0, 18]}...",
                  # section name is truncated to 10 characters followed by 3 dots.
                  section: "#{existing_section.name[0, 10]}..."
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

      purpose 'I can go back from the learning tracks page without losing any filled information' do
        step 'I am on the learning tracks page' do
          expect(page).to have_selector(
            '.panel .test-panel-header', text: 'Step 1: Choose an existing course and section'
          )
        end

        step 'Click on the "back" button' do
          with_element(LearningTracksPageObject.new(page)) do |pobject|
            pobject.button(:back).click
            wait_for_ajax
          end
        end

        with_element(ExpressCourseSetupPageObject.new(page)) do |pobject|
          expect(pobject.course_name).to eq(course_name)
          expect(pobject.start_date).to eq(start_date)
          expect(pobject.end_date).to eq(end_date)
          expect(pobject.number_of_sections).to eq(2)
          pobject.sections.each.with_index(1) do |section, i|
            expect(section.name).to eq("section #{i}")
          end

          pobject.button(:next).click
        end
      end

      purpose 'Learning tracks page' do
        with_element(LearningTracksPageObject.new(page)) do |pobject|
          step 'Wait for ajax completion and for the first step to be active' do
            wait_for_ajax
            Waiter.new.wait { pobject.panels.first.status == :active }
          end

          purpose 'In step 1, a course and a section must be selected' do
            step 'Step 1 is active' do
              expect(pobject.panels).to match(
                [
                  an_object_having_attributes(
                    header: 'Step 1: Choose an existing course and section',
                    status: :active
                  ),
                  an_object_having_attributes(
                    header: 'Step 2: Set the content available to assign',
                    status: :upcoming
                  ),
                  an_object_having_attributes(
                    header: 'Step 3: Set assignment due dates and settings',
                    status: :upcoming
                  ),
                  an_object_having_attributes(
                    header: 'Step 4: Review, modify, and generate assignments',
                    status: :upcoming
                  )
                ]
              )
            end

            expect(pobject.button(:save)).to be_disabled

            with_element(pobject.panels.first) do |panel|
              expect(panel.button(:select)).to be_disabled
              panel.course = existing_course.name
              expect(panel.button(:select)).to be_disabled
              panel.section = existing_course.sections.first.name
              expect(panel.button(:select)).to be_enabled

              panel.button(:select).click
            end


            step 'The 3rd step is active' do
              # The lessons range (step 2) will be automatically selected, so the 3rd
              # step is now the active one
              Waiter.new.wait do
                wait_for_ajax
                pobject.panels.third.status == :active
              end

              expect(pobject.panels).to match(
                [
                  an_object_having_attributes(
                    header: 'Step 1: Choose an existing course and section',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 2: Set the content available to assign',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 3: Set assignment due dates and settings',
                    status: :active
                  ),
                  an_object_having_attributes(
                    header: 'Step 4: Review, modify, and generate assignments',
                    status: :upcoming
                  )
                ]
              )

              expect(pobject.button(:save)).to be_disabled
            end

            purpose 'I can change the course template an select a track' do
              with_element(pobject.panels.first) do |panel|
                panel.button(:change_course_template).click
              end

              step 'The step 1 is now the active one' do
                Waiter.new.wait { pobject.panels.first.status == :active }
              end

              expect(pobject.panels).to match(
                [
                  an_object_having_attributes(
                    header: 'Step 1: Choose an existing course and section',
                    status: :active
                  ),
                  an_object_having_attributes(
                    header: 'Step 2: Set the content available to assign',
                    status: :upcoming
                  ),
                  an_object_having_attributes(
                    header: 'Step 3: Set assignment due dates and settings',
                    status: :upcoming
                  ),
                  an_object_having_attributes(
                    header: 'Step 4: Review, modify, and generate assignments',
                    status: :upcoming
                  )
                ]
              )

              expect(pobject.button(:save)).to be_disabled
            end

            step 'Select a track' do
              with_element(pobject.panels.first) do |panel|
                within(panel.learning_track_panel('Fully Online')) do
                  click_button 'Select Complete'
                end
              end
            end

            step 'The 3rd step is active' do
              # The lessons range (step 2) will be automatically selected, so the 3rd
              # step is now the active one
              Waiter.new.wait { pobject.panels.third.status == :active }

              expect(pobject.panels).to match(
                [
                  an_object_having_attributes(
                    header: 'Step 1: Choose an existing course and section',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 2: Set the content available to assign',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 3: Set assignment due dates and settings',
                    status: :active
                  ),
                  an_object_having_attributes(
                    header: 'Step 4: Review, modify, and generate assignments',
                    status: :upcoming
                  )
                ]
              )

              expect(pobject.button(:save)).to be_disabled
            end
          end

          purpose 'In step 2, a lesson range can be selected' do
            with_element(pobject.panels.second) do |panel|
              panel.start_lesson = 'Leccion 1'
              panel.end_lesson = 'Leccion 2'
            end

            step 'The 3rd step is active' do
              # The lessons range (step 2) will be automatically selected, so the 3rd
              # step is now the active one
              Waiter.new.wait { pobject.panels.third.status == :active }

              expect(pobject.panels).to match(
                [
                  an_object_having_attributes(
                    header: 'Step 1: Choose an existing course and section',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 2: Set the content available to assign',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 3: Set assignment due dates and settings',
                    status: :active
                  ),
                  an_object_having_attributes(
                    header: 'Step 4: Review, modify, and generate assignments',
                    status: :upcoming
                  )
                ]
              )

              expect(pobject.button(:save)).to be_disabled
            end
          end

          purpose 'In step 2, I can select included strands and activity types' do
            with_element(pobject.panels.second) do |panel|
              panel.show_options

              step 'I see strands included in the course' do
                expect(panel.strands).to contain_exactly(
                  an_object_having_attributes(
                    name: 'Contextos',
                    checked?: true
                  ),
                  an_object_having_attributes(
                    name: 'Estructura',
                    checked?: true
                  ),
                  an_object_having_attributes(
                    name: 'Fotonovela',
                    checked?: true
                  ),
                  an_object_having_attributes(
                    name: 'Panorama',
                    checked?: true
                  ),
                  an_object_having_attributes(
                    name: 'Pronuncuacion',
                    checked?: true
                  )
                )
              end

              step 'I can choose the strands to include' do
                panel.strands.first.uncheck
                panel.strands.third.uncheck
              end

              step 'I see activity types included in the course' do
                expect(panel.activity_types).to contain_exactly(
                  an_object_having_attributes(
                    name: 'Instructor-graded',
                    checked?: true
                  ),
                  an_object_having_attributes(
                    name: 'Microphone required',
                    checked?: true
                  ),
                  an_object_having_attributes(
                    name: 'Partner required',
                    checked?: true
                  )
                )
              end

              step 'I can select and unselect each activity type' do
                panel.activity_types.each(&:uncheck)

                panel.activity_types.first.check
                panel.activity_types.third.check
              end
            end
          end

          purpose 'In step 3, assignment due dates must be selected' do
            step 'Select a due date day' do
              vhl_check('Monday')
            end

            step 'The 4th step is active' do
              Waiter.new.wait { pobject.panels.fourth.status == :active }

              expect(pobject.panels).to match(
                [
                  an_object_having_attributes(
                    header: 'Step 1: Choose an existing course and section',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 2: Set the content available to assign',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 3: Set assignment due dates and settings',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 4: Review, modify, and generate assignments',
                    status: :active
                  )
                ]
              )

              expect(pobject.button(:save)).to be_enabled
            end

            step 'Unselect the due date day' do
              vhl_uncheck('Monday')
            end

            step 'The 3th step is now active' do
              Waiter.new.wait { pobject.panels.third.status == :active }

              expect(pobject.panels).to match(
                [
                  an_object_having_attributes(
                    header: 'Step 1: Choose an existing course and section',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 2: Set the content available to assign',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 3: Set assignment due dates and settings',
                    status: :active
                  ),
                  an_object_having_attributes(
                    header: 'Step 4: Review, modify, and generate assignments',
                    status: :upcoming
                  )
                ]
              )

              expect(pobject.button(:save)).to be_disabled
            end

            step 'Select due date days' do
              vhl_check('Monday')
              vhl_check('Wednesday')
              vhl_check('Friday')
            end

            step 'The 4th step is active' do
              Waiter.new.wait { pobject.panels.fourth.status == :active }

              expect(pobject.panels).to match(
                [
                  an_object_having_attributes(
                    header: 'Step 1: Choose an existing course and section',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 2: Set the content available to assign',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 3: Set assignment due dates and settings',
                    status: :finished
                  ),
                  an_object_having_attributes(
                    header: 'Step 4: Review, modify, and generate assignments',
                    status: :active
                  )
                ]
              )

              expect(pobject.button(:save)).to be_enabled
            end
          end

          purpose 'In step 4, I can review assignments' do
            step 'I can see all the due dates between the beginning and the end of the course' do
              with_element(pobject.panels.fourth) do |panel|
                expect(panel.due_dates).to match(
                  [
                    an_object_having_attributes(
                      label: 'We Mar 31',
                      checked?: true,
                      unlocked?: true
                    ),
                    an_object_having_attributes(
                      label: 'Fr Apr 02',
                      checked?: true,
                      unlocked?: true
                    ),
                    an_object_having_attributes(
                      label: 'Mo Apr 05',
                      checked?: true,
                      unlocked?: true
                    ),
                    an_object_having_attributes(
                      label: 'We Apr 07',
                      checked?: true,
                      unlocked?: true
                    ),
                    an_object_having_attributes(
                      label: 'Fr Apr 09',
                      checked?: true,
                      unlocked?: true
                    ),
                    an_object_having_attributes(
                      label: 'Mo Apr 12',
                      checked?: true,
                      unlocked?: true
                    ),
                    an_object_having_attributes(
                      label: 'We Apr 14',
                      checked?: true,
                      unlocked?: true
                    )
                  ]
                )
              end
            end

            step 'I see the number of assignments and hours of work per due date' do
              with_element(pobject.panels.fourth) do |panel|
                expect(panel.average_assignments_per_lesson).to eq('1')

                expect(panel.average_hours_of_work_per_due_date).to eq('0.6')
              end
            end
          end

          purpose 'In step 4, I can modify assignments' do
            purpose 'When I change the selected due dates, the stats are correctly updated,' do
              # NOTE: Unchecking the due dates takes place in separate blocks
              # to avoid Capybara stalled element error.
              1.upto(6) do |index|
                with_element(pobject.panels.fourth) do |panel|
                  panel.due_dates[index].uncheck
                end
              end

              # Give some time to the Vue code to update the values
              sleep 0.5
              with_element(pobject.panels.fourth) do |panel|
                expect(panel.average_assignments_per_lesson).to eq('1')

                expect(panel.average_hours_of_work_per_due_date).to eq('1.2')
              end
            end
          end

          purpose 'I see assignments been created when saving the course' do
            expect do
              pobject.button(:save).click

              within(page.find('.test-save-course-modal')) do
                expect(page).to have_selector(
                  '.test-job-inprogress-msg',
                  text: 'Setting up assignments for 2 sections. This will take a few moments.',
                  visible: :visible
                )

                Waiter.new.wait do
                  page.has_selector?('.test-job-complete-msg', visible: true)
                end

                expect(page).to have_selector(
                  '.test-job-complete-msg',
                  text: 'Assignments successfully created for 2 sections',
                  visible: :visible
                )
                click_button 'OK'
              end
            end.to change(Course, :count).by(1)
          end

          expect_flash_message(:notice, "Course #{course_name} was created successfully.")

          purpose 'The course and sections are saved in the database' do
            expect(Course.last).to have_attributes(
              name: course_name,
              start_date: start_date,
              end_date: end_date
            )
            expect(Course.last.sections).to match(
              [
                an_object_having_attributes(
                  name: 'section 1'
                ),
                an_object_having_attributes(
                  name: 'section 2'
                )
              ]
            )
          end
        end
      end
    end
  end
end
