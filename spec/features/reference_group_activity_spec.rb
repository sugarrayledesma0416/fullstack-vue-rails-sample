feature 'Notas culturales activity', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, family: 'vista_online_learning') }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity) { create_reference_activity_with_reference_groups(program) }
  # media item id needs to be 5 here, because that's the ID used in the XML fixture
  # for the reference group activity created for this test.
  let!(:media_item_image) { create(:media_item_image, filename: 'test.jpg', id: 5) }

  before do
    source_path = File.join('spec', 'fixtures', 'media_items', 'test.jpg')
    dest_path = media_item_image.full_filename
    FileUtils.makedirs(File.dirname(dest_path))
    FileUtils.cp(source_path, dest_path)
    @recycle_bin << dest_path
  end

  scenario 'Instructor sees an activity with reference groups' do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    # Go to a reference activity with a reference group
    visit section_activity_path(0, activity)
    expect(page).to have_selector('.has-background')
    expect(page).to have_selector('.f-headline-1', text: 'Lugares')
    expect(page).to have_selector('.f-headline-2', text: 'El morro')
    expect(page).to have_selector('.reference-p', text: 'Lorem impsum dolor sic amet.')
    expect(page).to have_selector('.u-float-rt')
    expect(page).to have_css("img[src*='#{media_item_image.filename}']")
  end
end
