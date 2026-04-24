feature 'Supersite Junior Progress Page',
        js: true, chrome: true, new_gb_sync: true do
  include RspecJsApiHelpers
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers

  let(:program) { create(:ss_jr_program) }
  let(:school) { create(:school) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:unit_1_image) { create(:media_item_image, filename: 'unit_1.png') }
  let(:unit_2_image) { create(:media_item_image, filename: 'unit_2.png') }
  let(:unit_1) do
    create(:unit, media_item_id: unit_1_image.id, program: program, rank: 1)
  end
  let(:unit_2) do
    create(:unit, media_item_id: unit_2_image.id, program: program, rank: 2)
  end
  let(:lesson_1) { create(:lesson, unit: unit_1, name: 'Lesson 1') }
  let(:lesson_2) { create(:lesson, unit: unit_2, name: 'Lesson 2') }
  let(:course) { create(:course, owner: instructor, program: program, school: school) }
  let(:section) { create(:section, instructor: instructor, course: course) }
  let(:strand_1_name) { 'Strand 1' }
  let(:strand_2_name) { 'Strand 2' }
  let(:strand_1) { create(:toc_entry, title: strand_1_name) }
  let(:strand_2) { create(:toc_entry, title: strand_2_name) }
  let(:due_date) { 1.day.ago.to_date }
  let(:category) { create(:category, course: course) }

  let(:concept_1) do
    create(
      :concept,
      id: strand_1.location,
      lesson: lesson_1,
      name: strand_1_name
    )
  end

  let(:concept_2) do
    create(
      :concept,
      id: strand_2.location,
      lesson: lesson_2,
      name: strand_2_name
    )
  end

  let(:strand_1_activity_1) do
    create(:activity, concept: concept_1, lesson: lesson_1)
  end

  let(:strand_1_activity_2) do
    create(:activity, concept: concept_1, lesson: lesson_1)
  end

  let(:strand_1_activity_3) do
    create(:activity, concept: concept_1, lesson: lesson_1)
  end

  let(:strand_2_activity_1) do
    create(:activity, concept: concept_2, lesson: lesson_2)
  end

  let(:strand_2_activity_2) do
    create(:activity, concept: concept_2, lesson: lesson_2)
  end

  let(:strand_2_activity_3) do
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'open_ended.xml'),
      program,
      lesson: lesson_2,
      strand_id: concept_2.id
    )
  end

  def link_image(media_item, fixture_file)
    source_path = File.join('spec', 'fixtures', 'media_items', fixture_file)
    dest_path = media_item.full_filename
    FileUtils.makedirs(File.dirname(dest_path))
    FileUtils.cp(source_path, dest_path)
    @recycle_bin << dest_path
  end

  before do
    link_image(unit_1_image, 'unit_1.png')
    link_image(unit_2_image, 'unit_2.png')

    # TODO: May not be necessary
    lesson_1.toc_entries = [strand_1]
    lesson_1.save!
    lesson_2.toc_entries = [strand_2]
    lesson_2.save!

    create(:active_enrollment, section: section, user: student)
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)
  end

  def submit(activity, submitted_at, points_earned, time_spent)
    create_gradebook_engine_submission(
      activity: activity,
      pending: false,
      points_earned: points_earned.to_f,
      section: section,
      submitted_at: submitted_at,
      student: student,
      time_spent: time_spent
    )

    create(
      :attempt_completed,
      activity: activity,
      section: section,
      user: student
    )
  end

  # TODO: unpend once chromedriver is updated in build image per MAE-78490
  xscenario 'As a Supersite Junior user, I see a donut with overall submission ' \
           'information and lesson-by-lesson lozenges on the Progress page' do
    # Assign all 6 activities for the same due date.
    [
      strand_1_activity_1, strand_1_activity_2, strand_1_activity_3,
      strand_2_activity_1, strand_2_activity_2, strand_2_activity_3
    ].each do |activity|
      create(
        :assignment,
        assignable: activity,
        category: category,
        due_date: due_date,
        section: section
      )
    end

    # Submit 3 on time, 2 late, and one should remain unsubmitted.
    on_time = due_date - 1.day
    late = due_date + 1.day
    submit(strand_1_activity_1, on_time, 3.0, 3600)
    submit(strand_1_activity_2, on_time, 5.0, 100)
    submit(strand_1_activity_3, late, 10.0, 200)
    submit(strand_2_activity_1, on_time, 6.0, 3600)
    submit(strand_2_activity_2, late, 6.0, 3660)

    visit gradebook_engine.jr_section_progress_path(
      program_id: program.id, section_id: section.id
    )

    expect(page).to have_content('83% complete')

    expect(page).to have_content('1 MISSING ASSIGNMENT')
    expect(page).to have_content('17% Missing')
    expect(page).to have_content('33% Late')
    expect(page).to have_content('50% On Time')

    # Find clock instances. These are in the shadow-dom not normal DOM, so
    # need to use javascript to retrieve the elements.
    clocks = page.evaluate_script('document.querySelectorAll("simple-clock")')

    # Verify that lessons are sorted in reverse order, so lozenge 1 contains
    # unit 2, and lozenge 2 contains unit 1

    within('.test-lesson-lozenge-1') do
      expect(page).to have_selector("img[src*='unit_2.png']")
      expect(page).to have_selector('.test-lesson-name', text: lesson_2.display_name)
      expect(page).to have_selector('.test-lesson-completion-status', text: 'to do')
      expect(page).to have_selector('.test-lesson-to-do-count', text: '1 assignment')
      expect(page).to have_button('Go')
    end

    expect(clocks.first[:hours]).to eq('2')
    expect(clocks.first[:minutes]).to eq('01')

    within('.test-lesson-lozenge-2') do
      expect(page).to have_selector("img[src*='unit_1.png']")
      expect(page).to have_selector('.test-lesson-name', text: lesson_1.display_name)
      expect(page).to have_selector('.test-lesson-completion-status', text: 'no missing work')
      # Don't show to-do count or Go button when all assignments are completed
      expect(page).to have_no_selector('.test-lesson-to-do-count')
      expect(page).to have_no_button('Go')
    end

    expect(clocks.last[:hours]).to eq('1')
    expect(clocks.last[:minutes]).to eq('05')

    within('.test-lesson-lozenge-1') do
      click_button('Go')
    end

    expect(page).to have_selector(
      '.test-activity-title',
      text: strand_2_activity_3.title
    )

    expect(page).to have_selector(
      '.test-current-activity-title',
      text: strand_2_activity_3.title
    )
  end
end
