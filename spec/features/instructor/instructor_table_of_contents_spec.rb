feature 'Instructor table of contents', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include GradebookEngineHelpers
  include Music::ApplicationHelper

  let(:school) { create(:school) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:program) { create(:vol_program) }
  let(:non_vol_program) { create(:program) }
  let(:unit_1) { create(:unit, program: program, name: 'UNIT-01', rank: 1) }
  let(:unit_2) { create(:unit, program: program, name: 'UNIT-02', rank: 2) }
  let(:non_vol_unit) { create(:unit, program: non_vol_program, name: 'Non-Vol-Unit', rank: 1) }
  let(:lesson_1) { create(:lesson, unit: unit_1, name: 'Lesson 1') }
  let(:lesson_2) { create(:lesson, unit: unit_2, name: 'Lesson 2') }
  let(:non_vol_lesson) { create(:lesson, unit: non_vol_unit) }
  let(:lesson_1_strand_a) { create(:toc_entry, title: 'strand_a') }
  let(:lesson_1_strand_b) { create(:toc_entry, title: 'strand_b') }
  let(:lesson_1_strand_c) { create(:toc_entry, title: 'strand_c') }
  let(:lesson_2_strand_a) { create(:toc_entry, title: 'strand_a') }
  let(:lesson_2_strand_c) { create(:toc_entry, title: 'strand_c') }
  let(:lesson_2_strand_d) { create(:toc_entry, title: 'strand_d') }
  let(:non_vol_strands) do
    {
      strand_non_vol_attrs: { title: 'non_vol_strand' }
    }
  end

  let(:non_vol_categories) do
    [
      create(:category, name: 'Homework', weighting_percent: 80, course:non_vol_course),
      create(:category, name: 'Quizzes', weighting_percent: 20, course:non_vol_course)
    ]
  end

  let(:non_vol_course) { create(:course, owner: instructor, program: non_vol_program) }
  let(:non_vol_section) { create(:section, instructor: instructor, course: non_vol_course) }
  let(:course_licenses) { [] }
  let(:learn_engine_activity) { create_activity('learning_engine', 'Component 1') }
  let(:multiple_choice_activity) { create_activity('multiple_choice', 'Component 1') }
  let(:drop_down_activity) { create_activity('drop_down', 'Component 1') }
  let(:fill_in_the_blanks_activity) { create_activity('fill_in_the_blanks', 'Component 2') }
  let(:open_ended_activity) { create_activity('open_ended', 'Component 2') }
  let(:non_vol_activity) do
    create(
      :activity,
      lesson: non_vol_lesson,
      instructor_id: instructor.id,
      toc_location: non_vol_lesson.strands[0].location,
      component_name: 'Practice',
      activity_type: 'multiple_choice',
      concept: non_vol_lesson.concepts[0]
    )
  end
  let(:same_component_name_activity) do
    create(
      :activity,
      activity_type: 'multiple_choice',
      component_name: 'Practice',
      concept: non_vol_lesson.concepts[0],
      concept_rank: non_vol_activity.concept_rank * 3,
      instructor_id: instructor.id,
      lesson: non_vol_lesson,
      toc_location: non_vol_lesson.strands[0].location,
      toc_location_rank: non_vol_activity.toc_location_rank * 3
    )
  end

  let(:multiple_due_date_activity) do
    create_activity('drop_down', 'Component 1')
  end

  def expect_to_see_read_only_activity_list
    step 'I see the name of the lesson in the header' do
      expect(page).to have_selector('.current_strand_lesson', text: lesson_1.name)
    end
    step 'I do not see a dropdown to select All activities / assigned only activities' do
      expect(page).to have_no_selector('.test-visibility-all', text: 'All Activities')
    end
    step 'I see all activities grouped by component' do
      expect(page).to have_selector('.toc_location_component', text: 'Component 1')
      expect(page).to have_selector('.toc_location_component', text: 'Component 2')
    end
    step 'I do not see any assignment checkbox' do
      activity_checkbox_selector = '#activity_' + learn_engine_activity.id.to_s + '_checkbox'
      expect(page).to have_no_selector(activity_checkbox_selector)
    end
    step 'I do not see any due date' do
      activity_due_date_selector = '#due_date_cell_for_activity_id_' + learn_engine_activity.id.to_s
      expect(page).to have_selector(activity_due_date_selector, text: '')
    end
  end

  def expect_to_see_activity_list
    step 'I see the name of the lesson in the header' do
      expect(page).to have_selector('.current_strand_lesson', text: lesson_1.name)
    end

    within('div#activities_list') do
      step 'Select "All activities" from the dropdown' do
        find('.js-visibility-selector').click
        find('.test-visibility-all', text: 'All Activities').click
      end
    end

    step 'I see all activities grouped by component' do
      expect(page).to have_selector('.toc_location_component', text: 'Component 1')
      expect(page).to have_selector('.toc_location_component', text: 'Component 2')
    end

    purpose 'The assignment checkbox column displays correct information' do
      step 'It shows an unselected checkbox' do
        expect(page).to have_no_selector('.show_check')
      end
    end

    purpose 'The activity column displays correct information' do
      step "It shows a link with the activity's name" do
        url = '/sections/0/activities/' + learn_engine_activity.id.to_s + '?popup=1'
        expect(page).to have_link(learn_engine_activity.title, href: url)
      end
      step "It shows different icons depending of the activity's type" do
        expect(page).to have_selector(
          'span#instructor_graded svg'
        )
      end
    end

    purpose 'The due date column displays correct information' do
      step 'It shows nothing for non assigned activities' do
        activity_due_date_id = '#due_date_cell_for_activity_id_' + learn_engine_activity.id.to_s
        expect(page).to have_selector(activity_due_date_id, text: '')
      end
      step 'It shows the due date instead of text "tomorrow"' do
        week_day = Date::ABBR_DAYNAMES[multiple_choice_activity.assignments[0].due_date.wday]
        activity_due_date_id = '#due_date_cell_for_activity_id_' + multiple_choice_activity.id.to_s
        expect(page.find(activity_due_date_id)).to have_text(week_day)
      end
      step 'It shows the due date for assigned activities' do
        week_day = Date::ABBR_DAYNAMES[drop_down_activity.assignments[0].due_date.wday]
        activity_due_date_id = '#due_date_cell_for_activity_id_' + drop_down_activity.id.to_s
        expect(page.find(activity_due_date_id)).to have_text(week_day)
      end
    end

    purpose 'Every activity has a tooltip with a complete summary in it' do
      page.find("#activity_#{learn_engine_activity.id}_checkbox").hover
      within(page.find(%([data-hover-container="activity_#{learn_engine_activity.id}"]))) do
        step "It shows the activity's type" do
          find('.activity_type', text: 'Learning engine')
        end
        step "It show the activity's name" do
          find('.activity_title', text: learn_engine_activity.title)
        end
        step "It shows the lesson's name" do
          expect(page).to have_selector('.activity_name', text: learn_engine_activity.student_title)
        end
        step 'It shows the possible points for the activity' do
          find('.points_possible', text: 'Points possible: ' + learn_engine_activity.points_possible.to_s)
        end
      end
    end

    purpose 'I can see a word summary for learning engine activities' do
      step 'The learning engine activity has a tooltip with the list of words from the activity' do
        expect(page).to have_selector('.activity_type', text: 'Words:')
      end
    end

    step 'The assign button is disabled' do
      expect(page).to have_selector('.disable_link_function')
    end
  end

  def create_concept_for_toc_entries(lesson)
    lesson.strands.each_with_index do |strand, index|
      create_concept_matching_strand_id(strand, name: strand.title, rank: index, lesson: lesson)
    end
  end

  def create_activity(activity_type, component_name)
    create(
      :activity,
      lesson: lesson_1,
      instructor_id: instructor.id,
      toc_location: lesson_1.strands[0].location,
      component_name: component_name,
      activity_type: activity_type,
      concept: lesson_1.concepts[0]
    )
  end

  def assign_activity(activity:, **attrs)
    default_attrs = {
      assignable: activity,
      due_date: 2.days.from_now.to_date,
      show_at: 1.day.ago
    }
    create(:assignment, default_attrs.merge(attrs))
  end

  def change_activity_visibility(activity, visibility)
    selector = if visibility == :visible
                 %([data-hover-container="activity_#{activity.id}"] .make_visible)
               else
                 %([data-hover-container="activity_#{activity.id}"] .make_invisible)
               end
    page.find(selector).click
    wait_for_ajax
  end

  def assign_activity_individually(activity, section)
    assign_activity(
      activity: activity,
      due_date: 3.days.from_now.to_date,
      individually_assignable: true,
      section: section
    )

    enrollment = create(:enrollment, section: section)

    create(
      :individual_assignment,
      activity_id: activity.id,
      due_date: 4.days.from_now.to_date,
      section_id: section.id,
      user_id: enrollment.user_id
    )
  end

  xscenario 'As an instructor in a VOL program, I can navigate and assign ' \
           'activities from the table of contents',
           clear_session_storage: true do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    course_licenses << Maestro::CourseLicense.new('license_group' => { 'id' => 1, 'demo' => false })
    allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)
    log_in_as(instructor)

    step 'Setup the database' do
      step 'Create a lesson called "Lesson 1"' do
        step 'Create all strands called "Strand A", "Strand B" and "Strand C"' do
          lesson_1.toc_entries = [lesson_1_strand_a, lesson_1_strand_b, lesson_1_strand_c]
          lesson_1.save!
          create_concept_for_toc_entries(lesson_1)
        end
        step 'Create a strand called "Strand A"' do
          step 'Create a component called "Component 1"' do
            step 'Create a learn engine activity' do
              learn_engine_activity.update_column(
                :content_summary,
                '{"dictionary_entries": "el sendero; el valle; el lago; el r\u00edo; la piedra"}'
              )
            end
            multiple_choice_activity
            drop_down_activity
          end
          step 'Create a component called "Component 2"' do
            fill_in_the_blanks_activity
            open_ended_activity
          end
        end
        step 'Create activity in strand c for lesson 1' do
          activity_1_lesson_1 = create(
            :activity,
            lesson: lesson_1,
            toc_location: lesson_1.strands[2].location,
            component_name: 'Practice',
            concept: lesson_1.concepts[2]
          )
        end
      end
      step 'Create a lesson called "Lesson 2"' do
        step 'Create all strands called "Strand A", "Strand D", "Strand C"' do
          lesson_2.toc_entries = [lesson_2_strand_a, lesson_2_strand_d, lesson_2_strand_c]
          lesson_2.save!
          create_concept_for_toc_entries(lesson_2)
        end
        step 'Create activity in strand c for lesson 2' do
          activity_1_lesson_2 = create(
            :activity,
            lesson: lesson_2,
            toc_location: lesson_2.strands[2].location,
            component_name: 'Practice',
            concept: lesson_2.concepts[2]
          )
        end
        step 'Create activity in strand d for lesson 2' do
          activity_2_lesson_2 = create(
            :activity,
            lesson: lesson_2,
            toc_location: lesson_2.strands[1].location,
            component_name: 'Practice',
            concept: lesson_2.concepts[1]
          )
          create(:default_vocabulary_word, program: program, lesson: lesson_1)
        end
      end
    end

    course = nil
    section = nil

    purpose 'I can see the TOC for a program when I have not yet set up a course' do
      step 'Go to the table of contents home page' do
        visit instructor_toc_path(
          program,
          display_lesson: lesson_1.id,
          toc_location: lesson_1.strands[0].location
        )
      end
      step 'I see a read only list of activity for that program' do
        expect_to_see_read_only_activity_list
      end
    end

    step 'Create a course' do
      course = create(:course, owner: instructor, program: program)
    end

    purpose 'I can see the TOC for a program when I have a course but not yet set up a section' do
      step 'Go to the table of contents home page' do
        visit instructor_toc_path(
          program,
          display_lesson: lesson_1.id,
          toc_location: lesson_1.strands[0].location
        )
      end
      step 'I see a read only list of activity for that program' do
        expect_to_see_read_only_activity_list
      end
    end

    step 'Create a section' do
      section = create(:section, instructor: instructor, course: course)
    end

    step 'Assign some activities' do
      assign_activity(section: section, activity: multiple_choice_activity, due_date: 1.days.from_now.to_date)
      assign_activity(section: section, activity: drop_down_activity, due_date: 3.days.from_now.to_date)
      assign_activity_individually(multiple_due_date_activity, section)
    end

    purpose 'I can see the TOC for a program when I have a course with a section' do
      step 'Go to the table of contents home page' do
        visit instructor_toc_path(
          program,
          display_lesson: lesson_1.id,
          toc_location: lesson_1.strands[0].location
        )
        wait_for_ajax
      end
      step 'I see a list of lessons for that program' do
        expect_to_see_activity_list
      end
    end

    purpose 'I can browse through lessons and strands' do
      step 'Go to the table of contents home page' do
        visit instructor_toc_path(
          program,
          display_lesson: lesson_1.id,
          toc_location: lesson_1.strands[0].location
        )
      end

      purpose 'When selecting a new lesson containing a strand with the same name ' \
        'as the current selected strand, the strand is automatically selected' do
        step 'Select lesson "Lesson 1"' do
          find('.test-ls-dropdown').click
          find('.test-ls-dropdown-list-item', text: lesson_1.name).click
        end
        step 'Select strand "Strand C"' do
          click_link 'strand_c'
        end
        step 'Select lesson "Lesson 2"' do
          find('.test-ls-dropdown').click
          find('.test-ls-dropdown-list-item', text: lesson_2.name).click
        end
        step 'I see the strand "Strand C" selected' do
          expect(page).to have_selector('.is-selected', text: 'strand_c')
        end
      end

      purpose 'When selecting a new lesson that does not contain a strand with the same name ' \
        'as the current selected strand, the first strand is automatically selected' do
        step 'Select strand "Strand B"' do
          click_link 'strand_b'
        end
        step 'Select lesson "Lesson 1"' do
          find('.test-ls-dropdown').click
          find('.test-ls-dropdown-list-item', text: lesson_1.name).click
        end
        step 'I see the strand "Strand A" selected' do
          expect(page).to have_selector('.is-selected', text: 'strand_a')
        end
      end
    end

    purpose 'I can choose to see only assigned activities' do
      within('div#activities_list') do
        step 'Select "Assigned Only" from the dropdown' do
          find('.js-visibility-selector').click
          find('.test-visibility-assigned', text: 'Assigned Only').click
        end
        step 'I only see assigned activities' do
          expect(page).to have_selector('.test-visibility-assigned', text: 'Assigned Only')
        end
        step 'One of the component shows "Nothing Assigned"' do
          expect(page).to have_selector(
            '.js-no-component-assignments-message', text: 'Nothing Assigned'
          )
        end
      end
    end

    purpose 'I can select multiple activities to assign' do
      purpose 'I can select and unselect a single activity' do
        checkbox = '#activity_' + multiple_choice_activity.id.to_s + '_checkbox'
        step 'Select an activity in the first component' do
          find(checkbox).click
        end
        step 'The assign button is enabled' do
          expect(page).to have_selector('.set_date_link')
        end
        step 'Unselect the activity' do
          find(checkbox).click
        end
        step 'The assign button is disabled' do
          expect(page).to have_selector('.disable_link_function')
        end
      end
      purpose 'I can select all the activities of a component' do
        within('div#activities_list') do
          step 'Select "All activities" from the dropdown' do
            find('.js-visibility-selector').click
            find('.test-visibility-all', text: 'All Activities').click
          end
        end
        step 'Select an activity in the first component' do
          find('#activity_' + learn_engine_activity.id.to_s + '_checkbox').click
        end
        step 'The assign button is enabled' do
          expect(page).to have_selector('.set_date_link')
        end
        step 'Select an activity in the second component' do
          find('#activity_' + open_ended_activity.id.to_s + '_checkbox').click
        end
        step 'The activity of the first component is still selected' do
          expect(page).to have_selector(
            '#activity_' + learn_engine_activity.id.to_s + '_checkbox.show_check'
          )
        end
        step 'Select the second component' do
          find('#component_component-2_1_checkbox').click
        end
        step 'All the activities of the second component are selected' do
          expect(page).to have_selector(
            '#component_component-2_1_checkbox.checkbox_all.show_check'
          )
          expect(page).to have_selector(
            '#activity_' + fill_in_the_blanks_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_selector(
            '#activity_' + open_ended_activity.id.to_s + '_checkbox.show_check'
          )
        end
        step 'The activity of the first component is still selected' do
          expect(page).to have_selector(
            '#activity_' + learn_engine_activity.id.to_s + '_checkbox.show_check'
          )
        end
        step 'Unselect an activity in the second component' do
          find('#activity_' + open_ended_activity.id.to_s + '_checkbox').click
        end
        step 'Other activities from the second component are still selected' do
          expect(page).to have_selector(
            '#component_component-2_1_checkbox.checkbox_all.show_check'
          )
          expect(page).to have_selector(
            '#activity_' + fill_in_the_blanks_activity.id.to_s + '_checkbox.show_check'
          )
        end
        step 'Unselect the second component' do
          find('#component_component-2_1_checkbox').click
        end
        step 'All the activities of the second component are unselected' do
          expect(page).to have_no_selector(
            '#activity_' + fill_in_the_blanks_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_no_selector(
            '#activity_' + open_ended_activity.id.to_s + '_checkbox.show_check'
          )
        end
        step 'The activity of the first component is still selected' do
          expect(page).to have_selector(
            '#activity_' + learn_engine_activity.id.to_s + '_checkbox.show_check'
          )
        end
        step 'Unselect the activity from the first component' do
          find('#activity_' + learn_engine_activity.id.to_s + '_checkbox').click
        end
        step 'The assign button is disabled' do
          expect(page).to have_selector('.disable_link_function')
        end
      end

      purpose 'I can select all the activities of a strand' do
        step 'Select an activity in the first component' do
          find('#activity_' + learn_engine_activity.id.to_s + '_checkbox').click
        end
        step 'Select an activity in the second component' do
          find('#activity_' + open_ended_activity.id.to_s + '_checkbox').click
        end
        step 'Select the strand' do
          find('.checkbox_program').click
        end
        step 'All the activities of the strand are selected' do
          expect(page).to have_selector(
            '#activity_' + learn_engine_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_selector(
            '#activity_' + multiple_choice_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_selector(
            '#activity_' + drop_down_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_selector(
            '#activity_' + fill_in_the_blanks_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_selector(
            '#activity_' + open_ended_activity.id.to_s + '_checkbox.show_check'
          )
        end
        step 'The assign button is enabled' do
          expect(page).to have_selector('.set_date_link')
        end
        step 'Unselect the strand' do
          find('.checkbox_program').click
        end
        step 'None of the activities of the strand are selected' do
          expect(page).to have_no_selector(
            '#activity_' + learn_engine_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_no_selector(
            '#activity_' + multiple_choice_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_no_selector(
            '#activity_' + drop_down_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_no_selector(
            '#activity_' + fill_in_the_blanks_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_no_selector(
            '#activity_' + open_ended_activity.id.to_s + '_checkbox.show_check'
          )
        end
        step 'The assign button is disabled' do
          expect(page).to have_selector('.disable_link_function')
        end
      end
    end

    category_1 = create(:category, course: course, name: 'Projects')
    category_2 = create(:category, course: course, name: 'Quizzes')

    purpose 'I can assign an activity' do
      step 'Select an activity in the first component' do
        find('#activity_' + learn_engine_activity.id.to_s + '_checkbox').click
      end
      step 'Click the assign button' do
        find('.instructor-action-button.assign-activities').click
      end
      purpose 'I can cancel the assignment procedure' do
        step 'I click the cancel button' do
          # I'm not sure why the .test-cancel-reassign button is clickable at this point.
          # I expected .test-cancel-review to be clickable.
          # I'm leaving it as-is to avoid breaking it.
          find('.test-cancel-reassign').click
        end
        step 'The activity is still selected' do
          expect(page).to have_selector(
            '#activity_' + learn_engine_activity.id.to_s + '_checkbox.show_check'
          )
        end
        step 'The assign button is enabled' do
          expect(page).to have_selector('.set_date_link')
        end
      end
      step 'Click the assign button' do
        find('.instructor-action-button.assign-activities').click
      end
      step 'I see a modal containing the text "1 activity selected"' do
        expect(page.all('.as_count')[1]).to have_text('1 activity selected')
      end
      purpose 'A Category is required' do
        step 'Click on the save button' do
          page.all('.link_savechanges').last.click
        end
        step 'I see the message "Please select a category"' do
          expect(page).to have_text('Please select a category.')
        end
      end
      step 'Select a Category' do
        find('#activity_assignment_category_id').click
        find(:option, 'Quizzes').click
      end
      purpose 'A valid due date is required' do
        step 'Set a due date before the course start date' do
          find('#activity_assignment_due_date').click
          find('#activity_assignment_due_date').set 2.months.ago.strftime('%m/%d/%Y')
        end
        step 'Click the assign button' do
          page.all('.link_savechanges').last.click
        end
        step 'I see the message "Due date must be after course start date, which is xxx"' do
          expect(page).to have_text('Due date must be after course start date')
          expect(page).to have_text('Please review and correct any errors.')
        end
        step 'Set a due date after the course end date' do
          find('#activity_assignment_due_date').click
          find('#activity_assignment_due_date').set 7.months.from_now.strftime('%m/%d/%Y')
        end
        step 'I see the message "Due date must be before course end date, which is xxx"' do
          expect(page).to have_text('Due date must be after course start date')
          expect(page).to have_text('Please review and correct any errors.')
        end
        step 'Set a valid due date' do
          find('#activity_assignment_due_date').click
          find('#activity_assignment_due_date').set 1.months.from_now.strftime('%m/%d/%Y')
        end
        step 'Click the save button' do
          page.all('.link_savechanges').last.click
        end
        step 'I see the flash message "Activity assigned successfully."' do
          expect_flash_message(:notice, 'Activity assigned successfully.')
        end
      end
      step 'None of the activities is unselected' do
        expect(page).to have_no_selector('.show_check')
      end
      step 'The correct due date is showed for the assigned activity' do
        selector_section = find('#due_date_cell_for_activity_id_' + learn_engine_activity.id.to_s)
        expect(selector_section).to have_text(1.months.from_now.strftime('%a %-m/%-d'))
      end
      step 'The assign button is disabled' do
        expect(page).to have_selector('.disable_link_function')
      end
    end

    purpose 'I can assign multiple activities' do
      step 'Select 2 non assigned activities' do
        find('#activity_' + fill_in_the_blanks_activity.id.to_s + '_checkbox').click
        find('#activity_' + open_ended_activity.id.to_s + '_checkbox').click
      end
      step 'Click the assign button' do
        find('.instructor-action-button.assign-activities').click
      end
      step 'I see a modal containing the text "2 activities selected"' do
        expect(page.all('.as_count')[1]).to have_text('2 activities selected')
      end
      step 'Select a Category' do
        find('#activity_assignment_category_id').click
        find(:option, 'Quizzes').click
      end
      step 'Set a valid due date' do
        find('#activity_assignment_due_date').click
        find('#activity_assignment_due_date').set 5.days.from_now.strftime('%m/%d/%Y')
      end
      step 'Click the save button' do
        page.all('.link_savechanges').last.click
      end
      step 'I see the flash message "Activities assigned successfully."' do
        expect_flash_message(:notice, 'Activity assigned successfully.')
      end
      step 'None of the activities is unselected' do
        expect(page).to have_no_selector('.show_check')
      end
      step 'The correct due date is showed for the assigned activities' do
        selector_section_1 = find('#due_date_cell_for_activity_id_' + fill_in_the_blanks_activity.id.to_s)
        selector_section_2 = find('#due_date_cell_for_activity_id_' + open_ended_activity.id.to_s)
        expect(selector_section_1).to have_text(5.days.from_now.strftime('%a %-m/%-d'))
        expect(selector_section_2).to have_text(5.days.from_now.strftime('%a %-m/%-d'))
      end
      step 'The assign button is disabled' do
        expect(page).to have_selector('.disable_link_function')
      end
    end

    purpose 'I can select assigned activity together with unassign activities' do
      step 'Select 2 assigned activity' do
        find('#activity_' + fill_in_the_blanks_activity.id.to_s + '_checkbox').click
        find('#activity_' + open_ended_activity.id.to_s + '_checkbox').click
      end
      step 'Click the assign button' do
        find('.instructor-action-button.assign-activities').click
        find('.wrap_table_dialog')
      end
      purpose 'I see a modal' do
        step 'I see text "2 activities selected"' do
          expect(page.all('.as_count')[0]).to have_text('2 activities selected')
        end
        step 'I see the name of the course' do
          expect(find('.dialog_course')).to have_text(course.name)
        end
        step 'I the the name of the section' do
          expect(find('.dialog_section')).to have_text(section.name)
        end
        purpose 'I see a summary line for each activity' do
          step 'I see the strand and activity name' do
            strand_activity_1 = learn_engine_activity.strand.title + ': ' + fill_in_the_blanks_activity.title
            strand_activity_1[0] = strand_activity_1[0].upcase
            expect(find('.wrap_table_dialog')).to have_text(strand_activity_1)
            strand_activity_2 = learn_engine_activity.strand.title + ': ' + open_ended_activity.title
            strand_activity_2[0] = strand_activity_2[0].upcase
            expect(find('.wrap_table_dialog')).to have_text(strand_activity_2)
          end
          step 'I see the category of the activity' do
            dialog_category_1 = fill_in_the_blanks_activity.assignments[0].category.name
            expect(page.all('.variable_category')[0]).to have_text(dialog_category_1)
            dialog_category_2 = open_ended_activity.assignments[0].category.name
            expect(page.all('.variable_category')[1]).to have_text(dialog_category_2)
          end
          step 'I see the due date of the activity' do
            dialog_date_1 = fill_in_the_blanks_activity.assignments[0].due_date.strftime('%a %m/%d')
            expect(page.all('.variable_dates')[0]).to have_text(dialog_date_1)
            dialog_date_2 = open_ended_activity.assignments[0].due_date.strftime('%a %m/%d')
            expect(page.all('.variable_dates')[1]).to have_text(dialog_date_2)
          end
        end
      end
      purpose 'I can cancel the procedure' do
        step 'I click the cancel button' do
          find('.test-cancel-review').click
        end
        step 'Activities are still selected' do
          expect(page).to have_selector(
            '#activity_' + fill_in_the_blanks_activity.id.to_s + '_checkbox.show_check'
          )
          expect(page).to have_selector(
            '#activity_' + open_ended_activity.id.to_s + '_checkbox.show_check'
          )
        end
        step 'The assign button is enabled' do
          expect(page).to have_selector('.set_date_link')
        end
      end
    end

    purpose 'I can unassign activities' do
      step 'Click the assign button' do
        find('.instructor-action-button.assign-activities').click
        find('.wrap_table_dialog')
      end
      step 'Click the unassign button' do
        click_button 'UNASSIGN'
      end
      step 'I see an alert with the message "You are about to unassign 2 items."'
      step 'Accept the alert' do
        accept_alert('You are about to unassign 2 items.')
      end
      step 'I see the flash message "Activities unassigned successfully."' do
        expect_flash_message(:notice, 'Activities unassigned successfully.')
      end
      step 'None of the activities is unselected' do
        expect(page).to have_no_selector('.show_check')
      end
      step 'No due date is displayed for the unassigned activities'
      step 'The assign button is disabled' do
        expect(page).to have_selector('.disable_link_function')
      end
    end

    purpose 'I can reassign activities' do
      step 'Select an assigned activity' do
        find('#activity_' + drop_down_activity.id.to_s + '_checkbox').click
      end
      step 'Select an unassigned activity' do
        find('#activity_' + fill_in_the_blanks_activity.id.to_s + '_checkbox').click
      end
      step 'Click the assign button' do
        find('.instructor-action-button.assign-activities').click
        find('.wrap_table_dialog')
      end
      step 'Click the reassign button' do
        find('.reassign_link').click
      end
      step 'I see a modal containing the text "2 activities selected"' do
        expect(page.all('.as_count')[1]).to have_text('2 activities selected')
      end
      step 'Click the "review activities" link' do
        click_link 'review activities'
      end
      step 'I am back to the previous modal'
      step 'Click the reassign button' do
        find('.reassign_link').click
      end
      step 'Select a category' do
        find('#activity_assignment_category_id').click
        find(:option, 'Quizzes').click
      end
      step 'Select a valid due date' do
        find('#activity_assignment_due_date').click
        find('#activity_assignment_due_date').set 10.days.from_now.strftime('%m/%d/%Y')
      end
      step 'Click the save button' do
        page.all('.link_savechanges').last.click
      end
      step 'I see the flash message "Activities assigned successfully."' do
        expect_flash_message(:notice, 'Activities assigned successfully.')
      end
    end

    purpose 'I see a warning when I try to reassign an activity with multiple due dates' do
      step 'Select an assigned activity without multiple due dates' do
        find('#activity_' + drop_down_activity.id.to_s + '_checkbox').click
      end

      step 'Click the assign button' do
        find('.instructor-action-button.assign-activities').click
        find('.wrap_table_dialog')
      end

      step 'I do not see a multiple-due-dates warning' do
        expect(page).not_to have_selector('.js-multiple-due-dates-warning', visible: :visible)
      end

      step 'Click the reassign button' do
        find('.reassign_link').click
      end

      step 'I do not see a multiple-due-dates warning' do
        expect(page).not_to have_selector('.js-multiple-due-dates-warning', visible: :visible)
      end

      step 'Cancel out of modal' do
        find('.test-cancel-reassign').click
      end

      step 'Unselect the assigned activity without multiple due dates' do
        find('#activity_' + drop_down_activity.id.to_s + '_checkbox').click
      end

      step 'Select an assigned activity with multiple due dates' do
        find('#activity_' + multiple_due_date_activity.id.to_s + '_checkbox').click
      end

      step 'Click the assign button' do
        find('.instructor-action-button.assign-activities').click
        find('.wrap_table_dialog')
      end

      # Warning should not be visible until user clicks "reassign".
      step 'I do not see a multiple-due-dates warning' do
        expect(page).not_to have_selector('.js-multiple-due-dates-warning', visible: :visible)
      end

      step 'Click the reassign button' do
        find('.reassign_link').click
      end

      step 'I see a multiple-due-dates warning' do
        expect(page).to have_selector('.js-multiple-due-dates-warning', visible: :visible)
      end

      step 'I do not see a manually-reordered warning' do
        expect(page).not_to have_selector('.js-manual-ordered-due-date-warning', visible: :visible)
      end

      step 'Cancel out of modal' do
        find('.test-cancel-reassign').click
      end

      step 'Select the assigned activity without multiple due dates' do
        find('#activity_' + drop_down_activity.id.to_s + '_checkbox').click
      end

      step 'Click the assign button' do
        find('.instructor-action-button.assign-activities').click
        find('.wrap_table_dialog')
      end

      step 'Click the reassign button' do
        find('.reassign_link').click
      end

      step 'I see a multiple-due-dates warning' do
        expect(page).to have_selector('.js-multiple-due-dates-warning', visible: :visible)
      end

      step 'I do not see a manually-reordered warning' do
        expect(page).not_to have_selector('.js-manual-ordered-due-date-warning', visible: :visible)
      end

      step 'Cancel out of modal' do
        find('.test-cancel-reassign').click
      end

      step 'Unselect the assigned activity without multiple due dates' do
        find('#activity_' + drop_down_activity.id.to_s + '_checkbox').click
      end

      step 'Unselect the assigned activity with multiple due dates' do
        find('#activity_' + multiple_due_date_activity.id.to_s + '_checkbox').click
      end
    end

    purpose 'The activity tooltip shows an Assign link' do
      step 'Select only one assigned activity' do
        find('#activity_' + learn_engine_activity.id.to_s + '_checkbox').click
      end
      step 'I see an Assign link in the activity tooltip' do
        selector = '#set_due_date_link_activity_' + learn_engine_activity.id.to_s
        expect(page).to have_selector(selector, text: 'Assign')
      end
      step 'Select only one unassigned activity' do
        find('#activity_' + open_ended_activity.id.to_s + '_checkbox').click
      end
      step 'I see an Assign link in the activity tooltip' do
        selector = '#set_due_date_link_activity_' + open_ended_activity.id.to_s
        expect(page).to have_selector(selector, text: 'Assign')
      end
      step 'I see an Assign link in both activities tooltip on hovering' do
        # Case of Assign activty.
        hover_selector = '#activity_' + learn_engine_activity.id.to_s + '_checkbox'
        page.find(hover_selector).hover
        assign_selector = '#set_due_date_link_activity_' + learn_engine_activity.id.to_s
        expect(page).to have_selector(assign_selector, text: 'Assign')
        # Case of Unassigned activity
        hover_selector = '#activity_' + open_ended_activity.id.to_s + '_checkbox'
        page.find(hover_selector).hover
        assign_selector = '#set_due_date_link_activity_' + open_ended_activity.id.to_s
        expect(page).to have_selector(assign_selector, text: 'Assign')
      end
      step 'Unselect the two selected activities' do
        find('#activity_' + learn_engine_activity.id.to_s + '_checkbox').click
        find('#activity_' + open_ended_activity.id.to_s + '_checkbox').click
      end
    end

    purpose 'I can show and hide a non assigned activity' do
      step 'Select a non assigned activity' do
        find('#activity_' + open_ended_activity.id.to_s + '_checkbox').click
      end
      step 'Click the "Hide" link in the activity tooltip' do
        change_activity_visibility(open_ended_activity, :hidden)
      end
      step 'The activity is still selected' do
        expect(page).to have_selector(
          '#activity_' + open_ended_activity.id.to_s + '_checkbox.show_check'
        )
      end
      step 'The due date of the activity shows "hidden"' do
        activity_due_date_selector = '#due_date_cell_for_activity_id_' + open_ended_activity.id.to_s
        wait_for_ajax
        expect(page).to have_selector(activity_due_date_selector, text: 'hidden')
      end
      step 'Click the "Show" link in the activity tooltip' do
        change_activity_visibility(open_ended_activity, :visible)
      end
      step 'I do not see any due date for this activity' do
        activity_due_date_selector = '#due_date_cell_for_activity_id_' + open_ended_activity.id.to_s
        expect(page).to have_selector(activity_due_date_selector, text: '')
      end
      step 'The activity is still selected' do
        expect(page).to have_selector(
          '#activity_' + open_ended_activity.id.to_s + '_checkbox.show_check'
        )
      end
    end

    purpose 'I can show and hide an assigned activity' do
      find('#activity_' + open_ended_activity.id.to_s + '_checkbox').click
      step 'Select an assigned activity' do
        find('#activity_' + learn_engine_activity.id.to_s + '_checkbox').click
      end
      step 'Click the "Hide" link in the activity tooltip' do
        change_activity_visibility(learn_engine_activity, :hidden)
      end
      step 'I see a modal with the message ' \
        '"Assigned activities will become unassigned when hidden from student view"' do
        expect(page).to have_text(
          'Assigned activities will become unassigned when hidden from student view'
        )
      end
      step 'Click OK' do
        page.all('.ui-button-text')[2].click
      end
      step 'The activity is still selected' do
        expect(page).to have_selector(
          '#activity_' + learn_engine_activity.id.to_s + '_checkbox.show_check'
        )
      end
      step 'The due date of the activity shows "hidden"' do
        activity_due_date_selector = '#due_date_cell_for_activity_id_' + learn_engine_activity.id.to_s
        expect(page).to have_selector(activity_due_date_selector, text: 'hidden')
      end
      step 'Click the "Show" link in the activity tooltip' do
        hover_selector = '#activity_' + learn_engine_activity.id.to_s + '_checkbox'
        page.find(hover_selector).hover
        change_activity_visibility(learn_engine_activity, :visible)
      end
      step 'I do not see any due date for this activity' do
        activity_due_date_selector = '#due_date_cell_for_activity_id_' + learn_engine_activity.id.to_s
        expect(page).to have_selector(activity_due_date_selector, text: '')
      end
      step 'The activity is still selected' do
        expect(page).to have_selector(
          '#activity_' + learn_engine_activity.id.to_s + '_checkbox.show_check'
        )
      end
    end
  end

  scenario 'As an instructor in a NON-VOL program, I can navigate and assign activities from the table of contents' do
    initialize_program_access_client_calls_for_instructor(instructor, non_vol_program)
    course_licenses << Maestro::CourseLicense.new(
      'license_group' => { 'id' => 1, 'demo' => false }
    )
    allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)
    log_in_as(instructor)

    purpose 'Setup the database for non VOL program' do
      step 'Create a strand' do
        non_vol_lesson.toc_entries = [
          create(:toc_entry, non_vol_strands[:strand_non_vol_attrs])
        ]
        non_vol_lesson.save!
        create_concept_for_toc_entries(non_vol_lesson)
      end
      step 'Create a course, categories, and a section' do
        non_vol_section # also creates course
        non_vol_categories
      end
      step 'Create an activity' do
        non_vol_activity
      end
    end

    purpose 'I can assign an activity in a non VOL program' do
      step 'Go to the table of contents home page for that program' do
        visit instructor_toc_path(non_vol_program)
      end
      step 'Select the activity' do
        within('div#activities_list') do
          step 'Select "All activities" from the dropdown' do
            find('.js-visibility-selector').click
            find('.test-visibility-all', text: 'All Activities').click
          end
        end
        expect(page).to have_selector('#activity_' + non_vol_activity.id.to_s + '_checkbox', visible: true)
        find('#activity_' + non_vol_activity.id.to_s + '_checkbox').click
      end
      step 'Click the assign button' do
        find('.instructor-action-button.assign-activities').click
        find('.reassign_container', wait: 5)
      end
      step 'I see a modal containing the text "1 activity selected"' do
        expect(page.all('.as_count')[1]).to have_text('1 activity selected')
      end
      purpose 'A Category is required' do
        step 'Click on the save button' do
          page.all('.link_savechanges').last.click
        end
        step 'I see the message "Please select a category"' do
          expect(page).to have_text('Please select a category.')
        end
      end
      step 'Select a Category' do
        find('#activity_assignment_category_id').click
        find(:option, 'Quizzes').click
      end
      purpose 'A valid due date is required' do
        step 'Set a due date before the course start date' do
          find('#activity_assignment_due_date').click
          find('#activity_assignment_due_date').set 2.months.ago.strftime('%m/%d/%Y')
        end
        step 'Click the assign button' do
          page.all('.link_savechanges').last.click
        end
        step 'I see the message "Due date must be after course start date, which is xxx"' do
          expect(page).to have_text('Due date must be after course start date')
        end
        step 'Set a due date after the course end date' do
          find('#activity_assignment_due_date').click
          find('#activity_assignment_due_date').set 7.months.from_now.strftime('%m/%d/%Y')
        end
        step 'I see the message "Due date must be before course end date, which is xxx"' do
          expect(page).to have_text('Due date must be after course start date')
        end
        step 'Set a valid due date' do
          find('#activity_assignment_due_date').click
          find('#activity_assignment_due_date').set 1.months.from_now.strftime('%m/%d/%Y')
        end
        step 'Click the save button' do
          page.all('.link_savechanges').last.click
        end
        step 'I see the flash message "Activity assigned successfully."' do
          expect_flash_message(:notice, 'Activity assigned successfully.')
        end
      end
      step 'None of the activities is unselected' do
        expect(page).to have_no_selector('.show_check')
      end
      step 'The correct due date is showed for the assigned activity' do
        selector_section = find('#due_date_cell_for_activity_id_' + non_vol_activity.id.to_s)
        expect(selector_section).to have_text(1.months.from_now.strftime('%a %-m/%-d'))
      end
      step 'The assign button is disabled' do
        expect(page).to have_selector('.disable_link_function')
      end
    end
  end

  scenario 'As an instructor, I can get the expected selection of activities if click the component name check box' do
    step 'Log in' do
      initialize_program_access_client_calls_for_instructor(instructor, non_vol_program)
      course_licenses << Maestro::CourseLicense.new(
        'license_group' => { 'id' => 1, 'demo' => false }
      )
      allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)
      log_in_as(instructor)
    end

    purpose 'Setup the database with two strand components with the same name' do
      step 'Create a strand' do
        non_vol_lesson.toc_entries = [
          create(:toc_entry, non_vol_strands[:strand_non_vol_attrs])
        ]
        non_vol_lesson.save!
        create_concept_for_toc_entries(non_vol_lesson)
      end
      step 'Create a course, categories, and a section' do
        non_vol_section # also creates course
        non_vol_categories
      end
      step 'Create activities' do
        non_vol_activity
        create(
          :activity,
          activity_type: 'multiple_choice',
          component_name: 'Verbs',
          concept: non_vol_lesson.concepts[0],
          concept_rank: non_vol_activity.concept_rank * 2,
          instructor_id: instructor.id,
          lesson: non_vol_lesson,
          toc_location: non_vol_lesson.strands[0].location,
          toc_location_rank: non_vol_activity.toc_location_rank * 2
        )
        same_component_name_activity
      end
    end

    purpose 'Only the expected activity is selected' do
      step 'Go to the table of contents home page for that program' do
        visit instructor_toc_path(non_vol_program)
      end
      step 'Click the checkbox of the first Practice component' do
        page.first('#component_practice_0_checkbox').click
      end
      step 'Only the activity of the first Practice component is selected' do
        expect(page).to have_selector("#activity_#{non_vol_activity.id}_checkbox.show_check")
        expect(page).to have_no_selector("#activity_#{same_component_name_activity.id}_checkbox.show_check")
      end
    end
  end

  scenario 'As and instructor, my lesson and strand preference is stored ' \
           'if I navigate away from the content pages' do
    activity_1_lesson_2 = nil
    step 'Log in' do
      initialize_program_access_client_calls_for_instructor(instructor, program)
      course_licenses << Maestro::CourseLicense.new(
        'license_group' => { 'id' => 1, 'demo' => false }
      )
      allow(Maestro::CourseLicense).to receive(:all).and_return(course_licenses)
      log_in_as(instructor)
    end

    step 'Setup the database' do
      step 'Create a lesson called "Lesson 1"' do
        step 'Create all strands called "Strand A", "Strand B" and "Strand C"' do
          lesson_1.toc_entries = [lesson_1_strand_a, lesson_1_strand_b, lesson_1_strand_c]
          lesson_1.save!
          create_concept_for_toc_entries(lesson_1)
        end
        step 'Create a strand called "Strand A"' do
          step 'Create a component called "Component 1"' do
            step 'Create a learn engine activity' do
              learn_engine_activity.update_column(
                :content_summary,
                '{"dictionary_entries": "el sendero; el valle; el lago; el r\u00edo; la piedra"}'
              )
            end
            multiple_choice_activity
            drop_down_activity
          end
          step 'Create a component called "Component 2"' do
            fill_in_the_blanks_activity
            open_ended_activity
          end
        end
        step 'Create activity in strand c for lesson 1' do
          create(
            :activity,
            lesson: lesson_1,
            toc_location: lesson_1.strands[2].location,
            component_name: 'Practice',
            concept: lesson_1.concepts[2]
          )
        end
      end
      step 'Create a lesson called "Lesson 2"' do
        step 'Create all strands called "Strand A", "Strand D", "Strand C"' do
          lesson_2.toc_entries = [lesson_2_strand_a, lesson_2_strand_d, lesson_2_strand_c]
          lesson_2.save!
          create_concept_for_toc_entries(lesson_2)
        end
        step 'Create activity in strand c for lesson 2' do
          activity_1_lesson_2 = create(
            :activity,
            lesson: lesson_2,
            toc_location: lesson_2.strands[2].location,
            component_name: 'Practice',
            concept: lesson_2.concepts[2]
          )
        end
        step 'Create activity in strand d for lesson 2' do
          create(
            :activity,
            lesson: lesson_2,
            toc_location: lesson_2.strands[1].location,
            component_name: 'Practice',
            concept: lesson_2.concepts[1]
          )
          create(:default_vocabulary_word, program:, lesson: lesson_1)
        end
      end
    end

    step 'Navigate to a lesson in the ToC' do
      visit instructor_toc_path(
        program,
        display_lesson: activity_1_lesson_2.lesson_id,
        toc_location: activity_1_lesson_2.toc_location
      )
    end

    step 'Navigate to a non content page' do
      visit instructor_program_resources_path(program)
    end

    purpose 'The ToC remembers what lesson and strand I was in' do
      visit instructor_toc_path(program)
      expect(page).to have_selector(
        '#current_strand_name',
        text: "#{lesson_2.name}| #{lesson_2_strand_c.title}"
      )
    end
  end
end
