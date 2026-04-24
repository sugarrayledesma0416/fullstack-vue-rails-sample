feature 'External Items',
        chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include RspecJsDownloadHelpers
  include GradebookEngineHelpers
  include CapybaraViewHelpers
  include WaitForNextPage

  let(:external_activity_class) { GradebookEngine::ExternalActivity }
  let(:external_assignment_class) { GradebookEngine::ExternalAssignment }
  let(:external_score_class) { GradebookEngine::ExternalScoreAction }
  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:student_3) { create(:student) }
  let(:school) { create(:school) }
  let(:program) { create(:program_with_toc_entries) }
  let!(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      program: program,
      school: school
    )
  end
  let(:category) do
    create(
      :category,
      course: course,
      credit_only: false,
      late_work_penalty: 'percent_per_day',
      penalty_percent: 50,
      weighting_percent: 50
    )
  end
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:non_external_activity) { create_open_ended_activity(program) }
  let(:concept) { non_external_activity.concept }
  let(:lesson) { non_external_activity.lesson }
  let(:strand) { non_external_activity.strand }
  let(:original_due_date) do
    # Avoid assigning on a Sunday to support tests of multiple assignment
    # days in the same week.
    week_containing(course.start_date + 7.days) + 1.day
  end
  let(:lesson_grade_class) { '.js-gb-table-side .c-gb-lesson-grade' }
  let(:default_title) { 'My first item' }
  let(:default_form_args) do
    {
      category: category,
      due_date: original_due_date,
      lesson: lesson,
      points_possible: 40,
      title: default_title
    }
  end

  def wait_for_scores_page
    wait_for_selector('label.c-filter-bar__label')
  end

  def week_containing(value)
    GradebookEngine::Week.week_containing(value)
  end

  def yyyy_mm_dd(value)
    value.strftime('%Y-%m-%d')
  end

  def mm_dd_yyyy(value)
    value.strftime('%m-%d-%Y')
  end

  def m_d_yy(value)
    value.strftime('%-m/%-d/%y')
  end

  def comment_field(student)
    "students[#{student.id}][comment]"
  end

  def points_field(student)
    "students[#{student.id}][points_earned]"
  end

  def navigate_to_edit_item_form(activity)
    column_header(activity).click
    header_menu(activity).find('a', text: 'Edit Item').click
  end

  def activities_for_week_url(week_id)
    gradebook_engine.course_section_scores_path(
      program.id,
      course.id,
      section_id: section.id,
      activities_strand_or_day: 'activity',
      lesson_or_due_date: 'week',
      all_lesson_or_week: week_id
    )
  end

  def activities_for_day_url(day_id)
    gradebook_engine.course_section_scores_path(
      program.id,
      course.id,
      section_id: section.id,
      activities_strand_or_day: yyyy_mm_dd(day_id),
      lesson_or_due_date: 'week',
      all_lesson_or_week: yyyy_mm_dd(week_containing(day_id))
    )
  end

  # This function will ONLY fill out the fields specified in args.
  # To fill out the whole form, pass in default_form_args, using .merge
  # if necessary to override any of the default values.
  def submit_external_item_form(args = {})
    fill_in(:external_item_title, with: args[:title]) if args.key?(:title)
    if args.key?(:due_date)
      fill_in(:pretty_due_date, with: mm_dd_yyyy(args[:due_date]))
      # Click away to ensure the datepicker closes
      find('body').click
    end
    # Wait for the datepicker to be hidden or it blocks access to other
    # form elements.
    el = find('#ui-datepicker-div')
    Waiter.new.wait { !el.visible? }

    if args.key?(:points_possible)
      fill_in(:external_item_points_possible, with: args[:points_possible])
    end
    if args.key?(:lesson)
      choose_from_selectbox(:external_item_lesson_id, args[:lesson].name)
    end
    if args.key?(:category)
      choose_from_selectbox(:external_item_category_id, args[:category].name)
    end
    if args.key?(:copy)
      vhl_check("Copy item to all sections in #{course.name}", allow_label_click: true)
    end

    wait_for_next_page do
      find_button('Save').click
    end
  end

  before do
    # Force a save of the lessons so that program_id gets propagated,
    # because the program_with_toc_entries factory doesn't correctly
    # handle this.
    program.lessons.each(&:save!)

    # Create a second section for copy to other sections in course test.
    create(:section, course: course, instructor: instructor)

    create(:enrollment, user: student_1, section: section)
    create(:enrollment, user: student_2, section: section)
    create(:enrollment, user: student_3, section: section)
    create(
      :assignment,
      assignable: non_external_activity,
      category: category,
      due_date: original_due_date,
      section: section
    )
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'As an instructor, I can add a new external item from the ' \
           'lessons level of the gradebook', downloads: true do
    step 'Go to the production gradebook page showing activity-level scores.' do
      wait_for_next_page do
        visit activities_for_lesson_url
      end
    end

    step 'Click on a button to Add item' do
      find('.js-add-item-btn', text: 'Add Item').click
    end

    points_possible = 40

    purpose 'I see validation errors when submitting invalid values' do
      # Leave some fields blank so we see validation erors.
      submit_external_item_form(
        due_date: original_due_date,
        points_possible: points_possible,
        title: default_title
      )

      expect_flash_message(:error, 'Failed to save item.')

      # Verify validation errors.
      expect(page).to have_text("Category can't be blank")
      expect(page).to have_text("Lesson can't be blank")
    end

    activity = nil
    purpose 'The valid external item is saved to the database' do
      # Submit with valid values.
      submit_external_item_form(
        category: category,
        due_date: original_due_date,
        lesson: lesson,
        points_possible: points_possible,
        title: default_title
      )

      # I should be taken to the gradebook page that shows the newly created item.
      wait_for_scores_page
      expect_url(activities_for_lesson_url)

      expect_flash_message(:notice, 'Item successfully added.')

      # I should have an ExternalActivity record in the database
      activity = external_activity_class.where(name: default_title).first
      expect(activity).to have_attributes(
        points_possible: points_possible,
        school_id: course.school_id
      )

      # I should have an ExternalAssignment record in the database
      assignment = external_assignment_class.where(
        external_activity_id: activity.id
      ).first
      expect(assignment).to have_attributes(
        category_id: category.id,
        day_id: original_due_date,
        lesson_id: lesson.id,
        school_id: course.school_id
      )
    end

    cell_id = nil
    new_column_header = nil

    purpose 'I see the new column in the gradebook, showing as Pending' do
      new_column_header = column_header(activity)
      expect(new_column_header).to have_text(default_title)

      cell_id = "ext#{activity.id}"

      expect_cell(
        student_1.id, cell_id, percent: 'Pending', points: 'Pending', late: false
      )

      enable_headless_downloads do
        click_button('Export')

        csv_content = last_download_content(encoding: 'windows-1252:utf-8')
        CSV.parse(csv_content, headers: true).each do |row|
          expect(row.fetch(activity.name)).to eq 'Pending'
        end
      end
    end

    purpose "I see a link to Enter Score when I click on a student's " \
            'pending grade.' do
      find(student_grade_selector(student_1.id, cell_id)).click
      expect(find('.test-modal-content')).to have_link('Enter Score')
      find('.test-modal-close').click
    end

    purpose 'I can access a link from the column header to enter scores' do
      new_column_header.click
      enter_scores_link = header_menu(activity).find('a', text: 'Enter Scores')
      expect(enter_scores_link).to be_visible

      step 'Click the link to go to the Enter Scores page' do
        enter_scores_link.click
      end
    end

    purpose 'I can enter scores for the item, including some which will ' \
            'trigger validation errors' do
      step 'Enter a score without a comment' do
        fill_in(points_field(student_1), with: 10)
      end

      step 'Enter an (invalid) score and a comment' do
        fill_in(points_field(student_2), with: 'bad')
        fill_in(comment_field(student_2), with: 'student 2 comment')
      end

      step 'Enter a comment without a score' do
        fill_in(comment_field(student_3), with: 'student 3 comment')
      end

      click_button('Save')

      expect_flash_message(:error, 'Failed to save scores.')
    end

    purpose 'I see validation errors, and the values I previously ' \
            'entered are maintained in the form after I submit' do
      purpose 'Expect to see validation warnings' do
        error_div = find('.c-form-item--error')
        expect(error_div).to have_field(points_field(student_2))
        expect(error_div).to have_text(
          "Must be a number from 0.0 to #{points_possible}.0"
        )
      end

      purpose 'All the fields are populated with the values I previously ' \
              'entered.' do
        expect(find_field(points_field(student_1)).value).to eq('10')
        expect(find_field(points_field(student_2)).value).to eq('bad')
        expect(find_field(comment_field(student_2)).value).to eq('student 2 comment')
        expect(find_field(comment_field(student_3)).value).to eq('student 3 comment')
      end

      step('Fix the bad value') { fill_in(points_field(student_2), with: 20) }

      click_button('Save')

      expect_flash_message(:notice, /success/)

      purpose 'I am taken back to the gradebook page that shows the ' \
              'external item' do
        wait_for_scores_page
        expect_url(activities_for_lesson_url)
      end
    end

    purpose 'I see the gradebook reflecting the scores I entered; and ' \
            'the scores I left blank show as pending' do
      step 'Verify the values in the html view' do
        expect_cell(
          student_1.id, cell_id, percent: 25.0, points: 10.0, late: false
        )
        expect_cell(
          student_2.id, cell_id, percent: 50.0, points: 20.0, late: false
        )
        expect_cell(
          student_3.id, cell_id, percent: 'Pending', late: false
        )
      end

      step 'Verify the values in the CSV view' do
        enable_headless_downloads do
          click_button('Export')
          csv_content = last_download_content(encoding: 'windows-1252:utf-8')
          rows = CSV.parse(csv_content, headers: true)
          expect(
            csv_row_for_student(rows, student_1).fetch(activity.name)
          ).to eq '25.0%'
          expect(
            csv_row_for_student(rows, student_2).fetch(activity.name)
          ).to eq '50.0%'
          expect(
            csv_row_for_student(rows, student_3).fetch(activity.name)
          ).to eq 'Pending'
        end
      end
    end

    purpose 'All the ExternalScoreAction records have the correct school' do
      GradebookEngine::ExternalScoreAction.all.each do |score|
        expect(score.school_id).to eq(school.id)
      end
    end

    purpose 'I see a link to the Enter Scores page in the student ' \
            'grade popup for any pending score' do
      find(student_grade_selector(student_1.id, cell_id)).click
      expect(find('.test-modal-content')).not_to have_link('Enter Score')
      find('.test-modal-close').click

      find(student_grade_selector(student_3.id, cell_id)).click
      find('.test-modal-content a', text: 'Enter Score').click
    end

    purpose 'I am able to edit the scores for the activity, and see ' \
            'the values I previously saved reflected in the form' do
      step 'Verify the form fields are pre-filled with the previously ' \
              'submitted values' do
        expect(find_field(points_field(student_1)).value).to eq('10.0')
        expect(find_field(comment_field(student_1)).value).to eq('')

        expect(find_field(points_field(student_2)).value).to eq('20.0')
        expect(find_field(comment_field(student_2)).value).to eq('student 2 comment')

        expect(find_field(points_field(student_3)).value).to eq('')
        expect(find_field(comment_field(student_3)).value).to eq('student 3 comment')
      end

      step 'Add a comment to student 1' do
        fill_in(comment_field(student_1), with: 'student 1 comment')
      end

      step 'Remove score from student 2' do
        fill_in(points_field(student_2), with: '')
      end

      step 'Add score to student 3' do
        fill_in(points_field(student_3), with: 40)
      end

      step('Save the scores') { click_button('Save') }

      step 'I amtaken back to the gradebook page that shows the ' \
           'external item' do
        wait_for_scores_page
        expect_url(activities_for_lesson_url)
      end
    end

    purpose 'The changes to the scores are reflected in the gradebook. ' \
            'Removing a score makes the grade show as Pending' do
      step 'score for student 1 should not have changed' do
        expect_cell(
          student_1.id, cell_id, percent: 25.0, points: 10.0, late: false
        )
      end

      step 'student 2 should now show as pending' do
        expect_cell(
          student_2.id, cell_id, percent: 'Pending', late: false
        )
      end

      step 'student 3 should now have a grade' do
        expect_cell(
          student_3.id, cell_id, percent: 100.0, points: 40.0, late: false
        )
      end
    end

    purpose 'I can copy an external item to all sections in the course \
             when I create a new one, if there is more than one section.' do
      step 'Click on a button to Add item' do
        find('.js-add-item-btn', text: 'Add Item').click
      end

      initial_items_count = external_assignment_class.count

      # Submit with valid values.
      submit_external_item_form(
        category: category,
        due_date: original_due_date,
        lesson: lesson,
        points_possible: points_possible,
        title: default_title,
        copy: true
      )

      # I should be taken to the gradebook page that shows the newly created item.
      wait_for_scores_page
      expect_url(activities_for_lesson_url)

      expect_flash_message(:notice, 'Item successfully added.')

      # I should have an ExternalActivity record in the database
      activity = external_activity_class.where(name: default_title).first
      expect(activity).to have_attributes(
        points_possible: points_possible,
        school_id: course.school_id
      )

      # I should have one new ExternalAssignment record for each section
      new_items_count = external_assignment_class.count
      expect(new_items_count - initial_items_count).to eq course.sections.count

      # I should have an ExternalAssignment record in the database
      assignment = external_assignment_class.where(
        external_activity_id: activity.id
      ).first
      expect(assignment).to have_attributes(
        category_id: category.id,
        day_id: original_due_date,
        lesson_id: lesson.id,
        school_id: course.school_id
      )
    end
  end

  scenario 'As an instructor, I can edit and delete an external item' do
    ## Part 1: Set up an existing External Item
    old_title = 'Before edits'
    old_points_possible = 30
    old_lesson = lesson
    old_category = category
    old_due_date = course.start_date + 2.days

    # Create new_category now so it shows up in the category dropdown.
    new_category = create(:category, course: course)
    # Refresh the association or only old_category shows up in the test scope.
    course.categories.reload

    activity = external_activity_class.create!(
      id: non_external_activity.id + 1,
      name: old_title,
      points_possible: old_points_possible,
      school_id: course.school_id
    )

    external_assignment_class.create!(
      external_activity_id: activity.id,
      category_id: old_category.id,
      day_id: old_due_date,
      lesson_id: old_lesson.id,
      school_id: course.school_id,
      section_id: section.id,
      week_id: week_containing(old_due_date)
    )

    ## Part 2: The Edit Item form is accessible via a link from the
    ##         column-header dropdown menu in the gradebook view that
    ##         shows the External Item.
    wait_for_next_page do
      visit activities_for_lesson_url
    end

    # Open the column header menu
    expect(column_header(activity)).to have_text(old_title)
    column_header(activity).click

    # Should see an Edit Item option in the dropdown
    edit_item_link = header_menu(activity).find('a', text: 'Edit Item')
    expect(edit_item_link).to be_visible

    # Click the link to go to the Edit Item form
    edit_item_link.click

    # Should see all the form fields filled out with the details of the
    # current ExternalActivity and ExternalAssignment
    expect(find_field(:external_item_title).value).to eq(old_title)
    expect(
      find_field(:external_item_points_possible).value
    ).to eq(old_points_possible.to_s)
    expect(
      find_field(:pretty_due_date).value
    ).to eq(mm_dd_yyyy(old_due_date))
    expect(find('#external_item_due_date', visible: false).value).to eq(yyyy_mm_dd(old_due_date))
    find('#external_item_lesson_id', text: old_lesson.name)
    find('#external_item_category_id', text: old_category.name)

    ## Part 3: Change the title, save, and verify the change.
    new_title = 'Edited title version 1'
    submit_external_item_form(title: new_title)

    # I should be taken back to the gradebook page that shows the external item
    wait_for_scores_page
    expect_url(activities_for_lesson_url)

    # The title in the column header should be the new title.
    expect(column_header(activity)).to have_text(new_title)

    ## Part 4: Change the due date, save, and verify the change.
    new_due_date = old_due_date + 2.days

    navigate_to_edit_item_form(activity)
    submit_external_item_form(due_date: new_due_date)

    # The due date in the column header should be the new due date.
    expect(column_header(activity)).to have_selector(
      '.c-due-date--gb', text: new_due_date.strftime('%-m/%d')
    )

    ## Part 5: Change the category, save.
    navigate_to_edit_item_form(activity)
    submit_external_item_form(category: new_category)

    # The column doesn't appear in the gradebook when viewing the old
    # category.
    choose_from_selectbox(:category_id, old_category.name)
    expect(page).not_to have_selector(header_id(activity))

    # The column appears in the gradebook when viewing the new category.
    choose_from_selectbox(:category_id, new_category.name)
    expect(page).to have_selector(header_id(activity))

    navigate_to_edit_item_form(activity)

    # Verify that all options show up in edit form. Incorrect config of
    # the rails select helper could result in first lesson now showing.
    open_selectbox_menu(:external_item_category_id)
    options = all(
      '#external_item_category_id option'
    )

    option_ids = options.map { |option| option['value'].to_i }
    option_labels = options.map(&:text)
    option_labels.shift
    # The default option isn't shown to the user, but it is still in the DOM, so
    # we have to include 0 in the list.
    expect(option_ids).to eq(course.categories.map(&:id).unshift(0))
    expect(option_labels).to eq(course.categories.map(&:name))

    # Go back to original gradesheet view.
    visit activities_for_lesson_url

    ## Part 6: When no scores have been entered for this item, points
    ##         possible can be edited.
    new_points_possible = old_points_possible + 10

    navigate_to_edit_item_form(activity)
    submit_external_item_form(points_possible: new_points_possible)

    expect(column_header(activity)['title']).to include(
      "Points Possible: #{new_points_possible.to_f}"
    )

    ## Part 7: Change the lesson, save, and verify the change. After saving,
    ##         verify redirect goes to the gradesheet view for the newly
    ##         selected lesson, so that the external item is visible.
    new_lesson = program.units[1].lessons.first

    navigate_to_edit_item_form(activity)
    submit_external_item_form(lesson: new_lesson)

    new_lesson_url = gradebook_engine.course_section_scores_path(
      program.id,
      course.id,
      section_id: section.id,
      activities_strand_or_day: 'activity',
      lesson_or_due_date: 'lesson',
      all_lesson_or_week: new_lesson.id
    )

    wait_for_scores_page
    expect_url(new_lesson_url)

    # Verify that all options show up in edit form. Incorrect config of
    # the rails select helper could result in first lesson not showing.
    navigate_to_edit_item_form(activity)

    open_selectbox_menu(:external_item_lesson_id)
    options = all(
      '#external_item_lesson_id option'
    )

    option_ids = options.map { |option| option['value'].to_i }
    option_labels = options.map(&:text)
    option_labels.shift
    lessons = section.lessons_covered
    expect(option_ids).to eq(lessons.map(&:id).unshift(0))
    expect(option_labels).to eq(lessons.map(&:name))

    ## Part 8: After adding a score, points possible should no longer be editable.
    ##         Points possible should be displayed but not be an editable field.
    external_score_class.create!(
      external_activity_id: activity.id,
      section_id: section.id,
      summation: {},
      user_id: student_1.id
    )

    # Reload the page
    visit page.current_url

    expect(page).not_to have_field(:external_item_points_possible)
    expect(find('.test-uneditable-points')).to have_text(new_points_possible)

    ## Part 9: From the edit form, a delete button with a confirmation popup
    ##         allows deletes the external activity record, the external
    ##         assignment record, (and all the scores?). The column should
    ##         no longer appear in the gradebook.
    find('.test-delete-item-btn').click
    find_button('Delete Item').click

    # We're taken back to the page where the external item was previously
    # being displayed.
    wait_for_scores_page
    expect_url(new_lesson_url)

    expect_flash_message(:notice, 'Item successfully deleted.')

    # The column doesn't appear in the gradebook.
    expect(page).not_to have_selector(header_id(activity))

    # Assignments for the external item have been deleted.
    expect(
      external_assignment_class.where(external_activity_id: activity.id)
    ).not_to exist

    # Scores for the external item have been deleted.
    expect(
      external_score_class.where(external_activity_id: activity.id)
    ).not_to exist

    # The external activity record has been deleted.
    expect(external_activity_class.where(id: activity.id)).not_to exist
  end

  scenario 'As an instructor, I can add a new external item from any ' \
           'of the different gradebook views, and after saving, be ' \
           'taken to the gradebook view that displays the new item' do
    ## Part 1: Add a new external item from a gradebook view showing
    ##         activities for a given week. Choose a due date in that
    ##         week. Verify taken to the same gradebook view and that
    ##         activity appears.
    first_week_id = week_containing(original_due_date)
    wait_for_next_page do
      visit activities_for_week_url(first_week_id)
    end

    find('.js-add-item-btn', text: 'Add Item').click
    submit_external_item_form(default_form_args)

    # I should be taken to the gradebook page that shows the newly created item.
    wait_for_scores_page
    expect_url(activities_for_week_url(first_week_id))

    # I should see the new column in the gradebook.
    activity = external_activity_class.where(name: default_title).first
    new_column_header = column_header(activity)
    expect(new_column_header).to have_text(default_title)

    ## Part 2: Edit the external item, and change the due date to a date
    ##         from a different week. On save, should be taken to the
    ##         gradebook view showing the activities for the newly chosen week.
    new_due_date = original_due_date + 1.week
    new_week_id = yyyy_mm_dd(week_containing(new_due_date))

    navigate_to_edit_item_form(activity)
    submit_external_item_form(due_date: new_due_date)

    # I should be on the gradebook page for the newly selected week.
    wait_for_scores_page
    expect_url(activities_for_week_url(new_week_id))

    # I should see the external item column in the new week view.
    expect(column_header(activity)).to have_selector(
      '.c-due-date--gb', text: new_due_date.strftime('%-m/%d')
    )

    # Remove the created activity before the next part.
    activity.destroy

    ## Part 3: Add a new external item from a gradebook view showing
    ##         activities for a given strand. Because there is no strand
    ##         view that displays external items, On save, should be taken
    ##         to the lesson view for that strand.
    strand = non_external_activity.concept

    activities_for_strand_url = gradebook_engine.course_section_scores_path(
      program.id,
      course.id,
      section_id: section.id,
      activities_strand_or_day: strand.id,
      lesson_or_due_date: 'lesson',
      all_lesson_or_week: lesson.id
    )
    wait_for_next_page do
      visit activities_for_strand_url
    end

    find('.js-add-item-btn', text: 'Add Item').click
    submit_external_item_form(default_form_args)

    # I should be taken to the gradebook page that shows the newly created item.
    # In this case, the strand view doesn't show external activities so we
    # have to go up to the lesson view.
    wait_for_scores_page
    expect_url(activities_for_lesson_url)

    # I should see the new column in the gradebook.
    activity = external_activity_class.where(name: default_title).first
    new_column_header = column_header(activity)
    expect(new_column_header).to have_text(default_title)

    # Remove the created activity before the next part.
    activity.destroy

    ## Part 4: Add a new external item from a gradebook view showing
    ##         activities for a given day. Set the due date to be that
    ##         day. Verify taken to the same gradebook view and that
    ##         activity appears.
    wait_for_next_page do
      visit activities_for_day_url(original_due_date)
    end

    find('.js-add-item-btn', text: 'Add Item').click
    submit_external_item_form(default_form_args)

    # I should be taken to the gradebook page that shows the newly created item.
    wait_for_scores_page
    expect_url(activities_for_day_url(original_due_date))

    # I should see the new column in the gradebook.
    activity = external_activity_class.where(name: default_title).first
    new_column_header = column_header(activity)
    expect(new_column_header).to have_text(default_title)
    expect(new_column_header).to have_selector(
      '.c-due-date--gb', text: original_due_date.strftime('%-m/%d')
    )

    ## Part 5: Edit the external item, and change the due date to a different
    ##         day. On save, should be taken to the gradebook view showing
    ##         the activities for the newly chosen day.
    new_due_date = original_due_date + 1.day

    navigate_to_edit_item_form(activity)
    submit_external_item_form(due_date: new_due_date)

    # I should be on the gradebook page for the newly selected week.
    wait_for_scores_page
    expect_url(activities_for_day_url(new_due_date))

    # I should see the external item column in the new week view.
    expect(column_header(activity)).to have_selector(
      '.c-due-date--gb', text: new_due_date.strftime('%-m/%d')
    )

    # Remove the created activity before the next part.
    activity.destroy

    ## Part 6: Add a new external item from the gradebook view showing
    ##         lesson grades for the whole section. On save, instead of
    ##         being taken back to this same view, should be taken to the
    ##         page showing the activities for the lesson in which the new
    ##         item was added.
    visit gradebook_engine.course_section_scores_path(
      program.id,
      course.id,
    section_id: section.id,
    lesson_or_due_date: 'lesson',
      activities_strand_or_day: 'activity',
      all_lesson_or_week: 'section'
    )


    find('.js-add-item-btn', text: 'Add Item').click
    submit_external_item_form(default_form_args)

    # I should be taken to the gradebook page that shows the newly created item.
    wait_for_scores_page
    expect_url(activities_for_lesson_url)

    # I should see the new column in the gradebook.
    activity = external_activity_class.where(name: default_title).first
    new_column_header = column_header(activity)
    expect(new_column_header).to have_text(default_title)

    # Remove the created activity before the next part.
    activity.destroy

    ## Part 7: Add a new external item from the gradebook view showing
    ##         week grades for the whole section. On save, instead of
    ##         being taken back to this same view, should be taken to the
    ##         page showing the activities for the week in which the new
    ##         item was added.
    visit gradebook_engine.course_section_scores_path(
      program.id,
      course.id,
      section_id: section.id,
      all_lesson_or_week: 'section',
      lesson_or_due_date: 'week'
      )

    find('.js-add-item-btn', text: 'Add Item').click
    submit_external_item_form(default_form_args)

    # I should be taken to the gradebook page that shows the newly created item.
    first_week_id = week_containing(original_due_date)
    wait_for_scores_page
    expect_url(activities_for_week_url(first_week_id))

    # I should see the new column in the gradebook.
    activity = external_activity_class.where(name: default_title).first
    new_column_header = column_header(activity)
    expect(new_column_header).to have_text(default_title)
  end

  scenario 'As an instructor, when I add an external item in a credit ' \
           'category, the scores display correctly' do
    credit_category = create(
      :category,
      course: course,
      credit_only: true,
      weighting_percent: 50
    )
    future_due_date = 5.days.from_now.to_date

    activity = external_activity_class.create!(
      id: non_external_activity.id + 1,
      name: 'not due yet item',
      points_possible: 20,
      school_id: course.school_id
    )

    external_assignment_class.create!(
      external_activity_id: activity.id,
      category_id: credit_category.id,
      day_id: future_due_date,
      lesson_id: lesson.id,
      school_id: course.school_id,
      section_id: section.id,
      week_id: week_containing(future_due_date)
    )

    past_due_date = 5.days.ago.to_date

    due_activity = external_activity_class.create!(
      id: non_external_activity.id + 2,
      name: 'already due item',
      points_possible: 20,
      school_id: course.school_id
    )

    external_assignment_class.create!(
      external_activity_id: due_activity.id,
      category_id: credit_category.id,
      day_id: past_due_date,
      lesson_id: lesson.id,
      school_id: course.school_id,
      section_id: section.id,
      week_id: week_containing(past_due_date)
    )

    # Go to the production gradebook page showing activity-level scores.
    wait_for_next_page do
      visit activities_for_lesson_url
    end

    ## Part 1: Verify that the activity due in the future doesn't count
    ##         towards the lesson grade because it's both pending and not
    ##         due yet. The already due activity doesn't count towards the
    ##         lesson grade because it's still pending.

    all("#{lesson_grade_class} .js-percent").each do |node|
      expect(node.text).to eq('0.0%')
    end

    all("#{lesson_grade_class} .js-points").each do |node|
      expect(node.text(:all)).to eq('0.0')
    end

    ## Part 2: Check score display for external activities that aren't due yet.
    ##         Before any scores entered, the activity should be displayed as
    ##         "Pending". When a comment is entered but no score, should
    ##         continue to show "Pending". When a numeric score is entered,
    ##         (even if it is 0), should show full credit.

    # Activity due in future should show as pending.
    cell_activity_id = "ext#{activity.id}"

    expect_cell(
      student_1.id, cell_activity_id, percent: 'Pending', points: 'Pending'
    )

    # Enter scores for activity due in future
    column_header(activity).click
    header_menu(activity).find('a', text: 'Enter Scores').click

    # Student 1 gets a comment but no score.
    fill_in(comment_field(student_1), with: 'student 1 comment')

    # Student 2 gets partial credit
    fill_in(points_field(student_2), with: 10)

    # Student 3 gets nothing
    fill_in(points_field(student_3), with: 0)

    # Save the scores
    click_button('Save')

    # I should be taken back to the gradebook page that shows the external item
    wait_for_scores_page
    expect_url(activities_for_lesson_url)

    # Student who got a comment but no score still shows as pending.
    expect_cell(
      student_1.id, cell_activity_id, percent: 'Pending', points: 'Pending'
    )

    # Student who got a partial credit shows full credit.
    expect_cell(
      student_2.id, cell_activity_id, percent: 100.0, points: 20.0
    )

    # Student who got a score of 0 shows full credit.
    expect_cell(
      student_3.id, cell_activity_id, percent: 100.0, points: 20.0
    )

    # Grading the activity that's not due yet should still have no effect
    # on the lesson grade.
    all("#{lesson_grade_class} .js-percent").each do |node|
      expect(node.text).to eq('0.0%')
    end

    all("#{lesson_grade_class} .js-points").each do |node|
      expect(node.text(:all)).to eq('0.0')
    end

    ## Part 2: Check score display for external activities that are already due.
    ##         Before any scores entered, the activity should be displayed as
    ##         "Pending". When a comment is entered but no score, should
    ##         continue to show "Pending". When a numeric score is entered,
    ##         (even if it is 0), should show full credit.

    # Already-due activity should show as pending before scores are entered.
    cell_activity_id = "ext#{due_activity.id}"

    expect_cell(
      student_1.id, cell_activity_id, percent: 'Pending', points: 'Pending'
    )

    # Enter scores for activity that is already due.
    column_header(due_activity).click
    header_menu(due_activity).find('a', text: 'Enter Scores').click

    # Student 1 gets a comment but no score.
    fill_in(comment_field(student_1), with: 'student 1 comment')

    # Student 2 gets partial credit
    fill_in(points_field(student_2), with: 10)

    # Student 3 gets nothing
    fill_in(points_field(student_3), with: 0)

    # Save the scores
    click_button('Save')

    # I should be taken back to the gradebook page that shows the external item
    wait_for_scores_page
    expect_url(activities_for_lesson_url)

    # Student who got a comment but no score still shows as pending.
    expect_cell(
      student_1.id, cell_activity_id, percent: 'Pending', points: 'Pending'
    )

    # Student who got a partial credit shows full credit.
    expect_cell(
      student_2.id, cell_activity_id, percent: 100.0, points: 20.0
    )

    # Student who got a score of 0 shows full credit.
    expect_cell(
      student_3.id, cell_activity_id, percent: 100.0, points: 20.0
    )

    # Activities with scores entered should now count towards lesson grade,
    # but the activity with no score entered should not change the lesson
    # grade.
    lesson_grades = all("#{lesson_grade_class} .js-percent").map(&:text)
    expect(lesson_grades).to match_array(['0.0%', '50.0%', '50.0%'])
  end

  scenario 'As an instructor, the filter bar has entries for lessons and ' \
           'days that have external but not regular items assigned' do
    # Assign an external item for the same day as a non-external assignment.
    # This should expose de-duping errors from the union of assignment days.
    non_conflicting_id = build_stubbed(:activity).id
    old_week_id = week_containing(original_due_date)

    activity = external_activity_class.create!(
      id: non_conflicting_id,
      name: default_title,
      points_possible: 40,
      school_id: course.school_id
    )

    external_assignment_class.create!(
      external_activity_id: activity.id,
      category_id: category.id,
      day_id: original_due_date,
      lesson_id: lesson.id,
      school_id: course.school_id,
      section_id: section.id,
      week_id: old_week_id
    )

    # Assign an external item for a different day and lesson as a non-external
    # assignment, to ensure options appear for days/lessons containing only
    # external items.
    due_date = original_due_date + 1.day
    week_id = week_containing(due_date)
    non_conflicting_id = build_stubbed(:activity).id
    last_lesson = program.units.last.lessons.last

    activity = external_activity_class.create!(
      id: non_conflicting_id,
      name: default_title,
      points_possible: 40,
      school_id: course.school_id
    )

    external_assignment_class.create!(
      external_activity_id: activity.id,
      category_id: category.id,
      day_id: due_date,
      lesson_id: last_lesson.id,
      school_id: course.school_id,
      section_id: section.id,
      week_id: week_id
    )

    # The top-level view of the gradebook, which displays a drop-down for
    # filtering by lesson.
    wait_for_next_page do
      visit gradebook_engine.course_section_scores_path(
        program.id,
        course.id,
      section_id: section.id,
      lesson_or_due_date: 'lesson',
        activities_strand_or_day: 'activity',
        all_lesson_or_week: 'section'
      )
    end

    # Should show the lesson that contains both the regular and external
    # item, and the lesson that contains only the external item.
    # .drop(1) to ignore the default "All activities" option.
    options = selectbox_options(:all_lesson_or_week).drop(1).map(&:text)
    expect(options).to eq([lesson.name, last_lesson.name])

    # When viewing activities for a week that contains days with regular
    # assignments assigned and days with only external items assigned,
    # the filterbar dropdown for selecting a specific day should list all
    # the days with either kind of assignment.
    visit activities_for_week_url(week_id)

    options = selectbox_options(:activities_strand_or_day).drop(1).map(&:text)
    expect(options).to eq([m_d_yy(original_due_date), m_d_yy(due_date)])

    # When viewing activities for a week that only contains days with
    # external items assigned, the filterbar dropdown for selecting a specific
    # day should list those days.
    next_week_due_date = original_due_date + 1.week

    # Change the due date to next week, which won't have any assignments in it.
    navigate_to_edit_item_form(activity)
    submit_external_item_form(due_date: next_week_due_date)

    next_week_id = week_containing(next_week_due_date)
    wait_for_scores_page
    expect_url(activities_for_week_url(next_week_id))

    # The filter-by-day dropdown should show the newly chosen day.
    options = selectbox_options(:activities_strand_or_day).drop(1).map(&:text)
    expect(options).to eq([m_d_yy(next_week_due_date)])
  end
end
