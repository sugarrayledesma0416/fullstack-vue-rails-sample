feature 'Grouped Vocab activity', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, family: 'vista_online_learning') }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson, unit: unit) }
  let(:strand_1_name) { 'Strand 1' }
  let(:strand_1) { create(:toc_entry, title: strand_1_name) }
  # media item id needs to be 5 here, because that's the ID used in the XML fixture
  # for the reference group activity created for this test.
  let!(:media_item_image) { create(:media_item_image, filename: 'test.jpg', id: 5) }

  let(:student_dashboard_url) do
    course_section_path(course_id: course.id, section_id: section.id)
  end

  let(:activity) do
    create_grouped_vocab_activity(
      program,
      lesson: lesson,
      max_attempts: nil,
      strand_id: strand_1.location
    )
  end

  before do
    lesson.toc_entries = [strand_1]
    lesson.save!
    source_path = File.join('spec', 'fixtures', 'media_items', 'test.jpg')
    dest_path = media_item_image.full_filename
    FileUtils.makedirs(File.dirname(dest_path))
    FileUtils.cp(source_path, dest_path)
    @recycle_bin << dest_path
  end

  scenario 'As a student, I am counted as having completed a grouped ' \
           'vocab activity when I open it', new_gb_sync: true do
    student = create(:student)
    create(:active_enrollment, section: section, user: student)
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)

    create(
      :assignment,
      assignable: activity,
      due_date: 2.days.ago.to_date,
      section: section
    )

    visit student_dashboard_url

    expect(page).to have_selector(
      '.test-previous-due-date',
      text: 'Previous Due Dates (1)'
    )
    click_link('Previous Due Dates')

    expect(page).to have_selector(
      '.test-strand-group-link',
      text: "#{lesson.name} : #{activity.concept.name}"
    )

    click_button('Start')

    within('#activityFooter') do
      click_link('Return to Dashboard')
    end

    expect(page).to have_selector(
      '.test-previous-due-date',
      text: 'Previous Due Dates (0)'
    )
  end
end
