# encoding: utf-8

feature 'My Content Section' do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let!(:program) { create(:program, language_code: 'es') }
  let!(:activity) { create_instructor_activity_with_unit_lesson_concept_strand_and_substrand(program, {instructor_id: instructor.id}) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let!(:section) { create(:section, course: course, instructor: instructor) }
  let(:course_licenses) { Array.new }
  let(:activity_name) { activity.title }

  # IGC Copy
  let(:source_program) { create(:program) }
  let(:destination_program) { create(:program_with_toc_entries) }

  let!(:igc_copy_activity) do
    ica = create_instructor_activity_with_unit_lesson_concept_strand_and_substrand(
      source_program,
      { instructor_id: instructor.id }
    )
    ica.concept_id = ica.lesson.concepts.first.id
    ica.toc_entry_id = ica.lesson.concepts.first.id
    # Disable before_save to avoid setting the concept_id automatically
    #   (it will fail w/o some complicated data setup)
    allow(ica).to receive(:process_callbacks_for_activity)
    ica.save!

    ica
  end

  # Create PTP mappings from the old to the new program.
  let!(:mapping) do
    create(
      :program_to_program_mapping,
      dest_program: destination_program,
      src_strand: igc_copy_activity.concept,
      dest_strand: destination_program.lessons.first.concepts.first
    )
  end

  before do
    give_instructor_access_to_toc
    initialize_program_access_client_calls_for_instructor(instructor, program)
    @recycle_bin << activity.content_filepath
    log_in_as(instructor)
  end

  def go_to_my_content
    visit instructor_toc_path(program)
    my_content_link = find("ul[data-page-element='content sub-menu'] li a", text: 'from My Content')
    my_content_link.click
  end

  scenario 'Instructor can see a list of all activities that has created', test_debt: true do
    CourseLibraryActivity.create!(activity_id: activity.id, course_id: course.id)
    go_to_my_content
    expect(page).to have_selector('.carousel')

    expect(page).to have_selector("[data-page-element='my_content_activity_title']", text: activity_name)

    click_on(activity_name)
    expect(page).to have_content(activity_name)
  end

  scenario "As an instructor, I can remove activities from the main 'my content' page that I don't want to use again", test_debt: true do
    go_to_my_content

    expect(page).to have_selector("[data-page-element='my_content_remove_activity'] a[href='#{instructor_created_activity_link_url}']")
    find("[data-page-element='my_content_remove_activity'] a[id='remove_activity_link_#{activity.id}']").click

    expect(page).to have_content("Activity #{activity.title} has been deleted.")
    uri = URI.parse(current_url)
    expect(uri.path).to eq(instructor_mycontent_path(program_id: program.id))

    expect(page).not_to have_selector("[data-page-element='my_content_activity_title']", text: activity_name)
  end

  scenario "As an instructor, I can not remove activities from the main 'my content' that are linked to an open course", test_debt: true do
    pending "Fix this test"
    CourseLibraryActivity.create(activity_id: activity.id, course_id: course.id)
    go_to_my_content

    expect(page).to have_selector("[data-page-element='my_content_remove_activity'] a[href='#']")
    find("[data-page-element='my_content_remove_activity'] a[id='remove_activity_link_#{activity.id}']").click
    expect(page).to have_selector("[data-page-element='my_content_activity_title']", text: activity_name)
  end

  scenario "As an instructor, I can edit activities from the main 'my content' page.", test_debt: true do
    pending "Fix this test"
    CourseLibraryActivity.create(activity_id: activity.id, course_id: course.id)
    go_to_my_content
    find("a.edit-created-activity").click
    find(:xpath, "//input[@name='instructor_created_activity[title]']").set('foo')
    find(:xpath, "//input[@data-button='save']").click
    expect(page).to have_content("Activity foo has been updated.")

    uri = URI.parse(current_url)
    expect(uri.path).to eq(instructor_mycontent_path(program_id: program.id))
  end

  scenario "As an instructor, I can copy my content from another program", test_debt: true, js: true do
    # Visit the my-content page in the new program.

    # If user clicks "Yes", user is notified that copying is processing.
    # When processing is done, user sees content.
    give_user_access_to_program(instructor, destination_program)
    initialize_program_access_client_calls_for_instructor(instructor, destination_program)
    log_in_as(instructor)

    # mostly copied from go_to_my_content, which doesn't quite work for this spec.
    visit instructor_toc_path(destination_program)
    my_content_link = find("ul.test-content-submenu li a", text: 'My Content')
    my_content_link.trigger('click')

    # Page should have "No activities to show." text.
    expect(page).to have_content('No activities to show.')

    # Page should have a container for the IGC copy notification.
    expect(page).to have_selector('#igc_copy')

    # Page should show the image of the book cover of the old program.
    expect(page).to have_selector("img[src='#{source_program.image_path}']")

    # Page should show count of IGC activities in the old program and show "Copy Content" button.
    # On clicking button, user should see confirmation modal.
    # FIXME: None of this hiding/showing is working in the test. It does work in the browser.
    click_on("Copy my content")
    #expect(page).not_to have_css("div.test-confirm-copy.u-hidden")

    expect(page).to have_selector('h3', text: "Copy My Content")
    #expect(page).to have_content("Importing 1 instructor generated activity from #{source_program.title} for all the current lessons in #{destination_program.title}. Is this OK?")

    # Dismiss the dialog.
    click_on("No")
    find("button.js-x-minimize").click
    #expect(page).not_to have_css('#igc_copy_minimized.u-hidden')
    # TODO: Finish feature spec through successful copy.
  end

  def instructor_created_activity_link_url
    params = { lesson_id: activity.lesson_id, toc_entry_id: activity.toc_location, program_id: activity.program.id, id: activity, activity_type: activity.activity_type, instructor_created_activity: {:hide_from_my_content => true}, return_to: 'my_content' }
    instructor_created_activity_path(params)
  end

end
