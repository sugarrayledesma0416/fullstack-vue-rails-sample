feature 'Assignment wizard', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include GradebookEngineHelpers

  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:program) { create(:program_with_toc_entries, family: 'vista_online_learning') }
  let(:course) do
    create(
      :course,
      name: 'Course 1',
      owner: instructor,
      program: program,
      school: school,
      start_date: mm_dd_yyyy(2.weeks.ago),
      end_date: mm_dd_yyyy(2.weeks.from_now)
    )
  end
  let!(:section) { create(:section, name: 'Section 1', instructor: instructor, course: course) }
  let!(:category) { create(:category, course: course) }
  let(:lesson) { program.units.first.lessons.first }

  let(:group_set) { create(:group_set, name: 'Learn Groups') }
  let(:learning_tracks_response) {}

  let(:course_package) { instance_double('Maestro::CoursePackage', id: 1) }
  let(:s3_bucket) { instance_double(Radner::S3Storage) }
  let(:learning_track_response) {}

  def mm_dd_yyyy(value)
    value.strftime('%m/%d/%Y')
  end

  def deselect_every_due_date
    due_dates_count = all('.test-due-dates').length
    due_dates_count.times do |index|
      input = find(".test-due-date-cb-#{index}")
      uncheck(input['id'], allow_label_click: true) if input['disabled'] != 'true'
    end
  end

  def select_every_due_date
    due_dates_count = all('.test-due-dates').length
    due_dates_count.times do |index|
      input = find(".test-due-date-cb-#{index}")
      check(input['id'], allow_label_click: true) if input['disabled'] != 'true'
    end
  end

  def build_learning_track_response
    activity_hash = {}
    track_groups = []
    learning_track_activities = []
    strand_names = []
    learning_track_response_strands = {}
    lesson.strands.each do |strand|
      strand_names.push(strand.title)
      learning_track_response_strands[strand.title] = { name: strand.title }
      activity = create(
        :activity,
        activity_location_attributes(program, strand_id: strand.location, lesson: lesson)
      )

      activity_hash[activity.id.to_s] = {
        activity_type: Activity.humanize_activity_type(activity.activity_type),
        id: activity.id,
        lesson_name: activity.lesson.name,
        minutes_to_complete: 10,
        strand: strand.title,
        strand_name: strand.title,
        substrand: '',
        title: activity.title,
        unit_id: activity.lesson.unit.id
      }

      track_group = create(
        :track_group,
        program: program,
        name: 'learn',
        group_set: group_set,
        concept: activity.concept,
        lesson: lesson
      )

      track_groups.push(track_group)
      learning_track_activities.push(
        id: activity.id,
        group: 'Learn',
        group_id: track_group.id,
        category: 'category1',
        due_date: mm_dd_yyyy(2.weeks.from_now)
      )
    end

    {
      tracks: {
        'Fully Online': {
          subtracks: {
            Complete: {
              activities: learning_track_activities,
              strands: strand_names,
              categories: 'Base Categories',
              first_unit_id: program.units.first.id,
              last_unit_id: program.units.last.id,
              rank: 1,
              units: []
            }
          }
        }
      },
      activities: activity_hash,
      strands: learning_track_response_strands,
      categories: { 'Base Categories': {} }
    }
  end

  before do
    learning_tracks_response = build_learning_track_response
    # Mock S3 API calls to retreive learning tracks
    allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
    units = []
    program.units.each.with_index(1) do |unit, index|
      learning_track_unit = unit.attributes
      learning_track_unit['label'] = "Leccion #{index}"
      units.push(learning_track_unit)
    end
    learning_tracks_response[:tracks][:"Fully Online"][:subtracks][:Complete][:units] = units
    allow(s3_bucket).to receive(:fetch).and_return(learning_tracks_response)
    allow(s3_bucket).to receive(:directory_files).and_return([])
    allow(LearningTrack::ActivityExporter).to receive(:activities_json)

    initialize_program_access_client_calls_for_instructor(instructor, program)
    allow(Maestro::CoursePackage).to receive(:all_for_course).and_return([course_package])
    instructor.schools << school
    # Set up program config
    create(:vol_program_config, program: program)
    log_in_as(instructor)
  end

  def follow_assignment_wizard_link_from_gear_menu(section_id)
    within(".test-section-#{section_id}") do
      step 'Click on the gear of the section' do
        find('.test-gear').click
      end
      step 'Click on the "Assignment Wizard" link' do
        click_link('Assignment Wizard')
      end
    end
  end

  # Skipped to investigate why this page doesnt work on test
  xscenario 'As an instructor, I can change the assignment wizard settings', js: true do
    visit instructor_dashboard_path(program, school)
    follow_assignment_wizard_link_from_gear_menu(section.id)

    visit instructor_dashboard_path(program, school)
    follow_assignment_wizard_link_from_gear_menu(section.id)

    step 'In step 1, Select a track' do
      within('.test-choose-template-main') do
        step 'The course dropdown is visible' do
          expect(page).to have_selector('.test-previous-courses', visible: :visible)
        end
        step 'The section dropdown is visible' do
          expect(page).to have_selector('.test-previous-sections', visible: :visible)
        end

        within('.test-predefined-track-0') do
          find('.test-expander-button').click
          click_button 'Select Complete', visible: :visible
        end
      end
    end

    step 'In step 2, select a lesson range' do
      select 'Leccion 1', from: 'dropdown-step2-lesson-start'
      select 'Leccion 2', from: 'dropdown-step2-lesson-end'
    end

    wait_for_ajax

    step 'In step 3, select a due date day' do
      expect(page).to have_selector('.test-due-day-label-0', text: 'Sunday', visible: :visible)
      check('dueDay0', allow_label_click: true)
    end

    step 'In step 4, deselect every due date' do
      deselect_every_due_date
      step 'The average assignments per lesson is 0' do
        expect(page).to have_selector('.test-activities-per-lesson', visible: :visible)
        expect(find('.test-activities-per-lesson').text).to eq('0')
      end
      step 'the average hours of work per due date is 0.0' do
        expect(find('.test-assignments-per-lesson').text).to eq('0.0')
      end
    end

    step 'In step 4, select every due date' do
      select_every_due_date

      # Total 6 activities distributed among 2 enabled due dates
      # so 6/2 average assignment per lesson.
      step 'The average assignments per lesson is 3' do
        expect(find('.test-activities-per-lesson').text).to eq('3')
      end

      # Total minutes to complete
      # = 10 (minutes to complete for each activity) * 6 activities
      # Total time taken in hours
      # = ( Total minutes to complete / Due dates count ) / 60
      # = ( 60 / 2) / 60 = 0.5
      step 'the average hours of work per due date is 0.5' do
        expect(find('.test-assignments-per-lesson').text).to eq('0.5')
      end
    end

    step 'In step 4, open group menu' do
      step 'Move last activity to next due date in group menu' do
        unlocked_due_dates = all('.test-unlocked-due-date-wrapper')

        # Calculating graphs count in due dates to compare them after activities
        # are moved to previous / next due dates.
        # We are using term first due date & second due date etc because these are dynamic
        # and depend upon today's date.
        # This is graph count in first unlocked due date
        first_graph_count = unlocked_due_dates[0].all(
          '.test-due-date-graph-container svg g'
        ).length
        # This is graph count in second unlocked due date
        second_graph_count = unlocked_due_dates[1].all(
          '.test-due-date-graph-container svg g'
        ).length

        step 'Click on the last graph block in first unlocked due date' do
          unlocked_due_dates[0].all(
            '.test-due-date-graph-container svg g'
          )[first_graph_count - 1].click
        end
        step 'Group Menu modal is displayd with 1 activity' do
          expect(page).to have_selector('.test-group-menu-modal', visible: :visible)
          expect(all('.test-group-menu-modal .test-activity-row').length).to eq(1)
        end
        step 'Group Menu modal is displayd with link "Move last activity to next due date"' do
          expect(page).to have_selector('.test-group-menu-modal .test-move-last-activity')
        end
        step 'Click on Move last activity link' do
          find('.test-group-menu-modal .test-move-last-activity').click
        end
        step 'No activity message is displayed in the group menu modal' do
          expect(page).to have_selector('.test-group-menu-modal .test-no-activities')
        end
        step 'Close group menu modal' do
          find('.test-group-menu-modal  .test-modal-close-button').click
        end
        step 'Group menu modal is not displayed' do
          expect(page).to have_no_selector('.test-group-menu-modal', visible: :visible)
        end
        step 'Warn about changes modal is displayed' do
          expect(page).to have_selector('.test-warn-about-changes-modal', visible: :visible)
        end
        step 'Close warn about changes modal' do
          find('.test-warn-about-changes-modal  .test-modal-close-button').click
        end
        step 'Warn about changes modal is not displayed' do
          expect(page).to have_no_selector('.test-warn-about-changes-modal', visible: :visible)
        end

        # find latest due dates elements again
        unlocked_due_dates = all('.test-unlocked-due-date-wrapper')

        step 'Graph block count decreases for first unlocked due date' do
          expect(
            unlocked_due_dates[0].all('.test-due-date-graph-container svg g').length
          ).to eq(first_graph_count - 1)
        end
        step 'Graph block count increases for second unlocked due date' do
          expect(
            unlocked_due_dates[1].all('.test-due-date-graph-container svg g').length
          ).to eq(second_graph_count + 1)
        end
      end

      step 'Move first activity to previous due date in group menu' do
        unlocked_due_dates = all('.test-unlocked-due-date-wrapper')

        # This is graph count in first unlocked due date
        first_graph_count = unlocked_due_dates[0].all(
          '.test-due-date-graph-container svg g'
        ).length
        # This is graph count in second unlocked due date
        second_graph_count = unlocked_due_dates[1].all(
          '.test-due-date-graph-container svg g'
        ).length

        step 'Click the first graph block in second unlocked due date' do
          unlocked_due_dates[1].all('.test-due-date-graph-container svg g')[0].click
        end
        step 'Group Menu modal is displayd with 1 activity' do
          expect(page).to have_selector('.test-group-menu-modal', visible: :visible)
          expect(all('.test-group-menu-modal .test-activity-row').length).to eq(1)
        end
        step 'Group Menu modal is displayd with link "Move first activity to previous due date' do
          expect(page).to have_selector('.test-group-menu-modal .test-move-first-activity')
        end
        step 'Move first activity in list' do
          find('.test-group-menu-modal .test-move-first-activity').click
        end
        step 'No activity message is displayed in the group menu modal' do
          expect(page).to have_selector('.test-group-menu-modal .test-no-activities')
        end
        step 'Close group menu modal' do
          find('.test-group-menu-modal  .test-modal-close-button').click
        end
        step 'Group menu modal is not displayed' do
          expect(page).to have_no_selector('.test-group-menu-modal', visible: :visible)
        end
        step 'Warn about changes modal is displayed' do
          expect(page).to have_selector('.test-warn-about-changes-modal', visible: :visible)
        end
        step 'Close warn about changes modal' do
          find('.test-warn-about-changes-modal  .test-modal-close-button').click
        end
        step 'Warn about changes modal is not displayed' do
          expect(page).to have_no_selector('.test-warn-about-changes-modal', visible: :visible)
        end

        # find latest due dates elements again
        unlocked_due_dates = all('.test-unlocked-due-date-wrapper')

        step 'Graph block count increases for first unlocked due date' do
          expect(
            unlocked_due_dates[0].all('.test-due-date-graph-container svg g').length
          ).to eq(first_graph_count + 1)
        end
        step 'Graph block count decreases for second unlocked due date' do
          expect(
            unlocked_due_dates[1].all('.test-due-date-graph-container svg g').length
          ).to eq(second_graph_count - 1)
        end
      end
    end

    step 'Click the "save" button' do
      page.find('.test-assignment-wizard-save', text: 'Save').click
    end
    wait_for_ajax

    step 'I can see the "Category Mapping" modal' do
      expect(page).to have_selector('.test-category-mappings-modal', visible: :visible)
    end

    step 'I see the modal title saying "Setting up assignments for 2 section."' do
      expect(page).to have_selector(
        '.test-category-mappings__title',
        text: 'For the activities in each Learning Group, choose a gradebook category.',
        visible: :visible
      )
    end

    step 'The "save" button on "Category Mapping" modal is disabled' do
      expect(
        find('.test-save-category-mappings', text: 'Save')
      ).to be_disabled
    end

    step 'Select "Gradebook Categories" for all "Learning Group"' do
      all('.test-mappings-table__category-select').each do |select_elm|
        select_elm.find("option[value='#{category.id}']").select_option
      end
    end

    step 'The "save" button on "Category Mapping" modal is enabled' do
      expect(
        find('.test-save-category-mappings', text: 'Save')
      ).not_to be_disabled
    end

    step 'Save the "Category Mapping" settings' do
      find('.test-save-category-mappings', text: 'Save').click
    end

    wait_for_ajax

    within(page.find('.test-save-course-modal')) do
      expect(page).to have_selector(
        '.test-job-complete-msg__heading',
        text: 'Assignments successfully created!',
        visible: :visible
      )
      click_button 'OK'
    end

    step 'I am on the instructor dashboard page' do
      expect(page).to have_current_path(instructor_dashboard_path(program))
    end
  end
end
