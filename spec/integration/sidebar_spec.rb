feature 'sidebar' do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, family: 'vista_online_learning') }
  let(:sidebar) do
    path = File.join('spec', 'fixtures', 'xml', 'sidebar.xml')
    create_activity_with_content(path, program)
  end
  let(:fib) do
    path = File.join('spec', 'fixtures', 'xml', 'sidebar_fib.xml')
    create_activity_with_content(path, program)
  end

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  # When the classes are updated in the Maestro Activity Engine views, it's important to
  # update this specs.

  scenario 'I can view a sidebar with multiple old-style references' do
    visit section_activity_path(0, sidebar)
    expect(page).to have_selector(%([class~="test-phrase-group"]), count: 3)
  end

  scenario 'I can view a sidebar with a vocab chart' do
    visit section_activity_path(0, sidebar)
    # TODO: Replace this class here and in the view with 'test-vocab-chart'.
    expect(page).to have_selector(%([class~="c-vocab-chart"]))
  end

  scenario 'I can view a sidebar with a regional variation' do
    visit section_activity_path(0, sidebar)
    expect(page).to have_selector(%([class~="test-regional-variation"]))
  end

  scenario 'I can view a fill in the blanks activity with multiple sidebars and multiple sidebar refs' do
    visit section_activity_path(0, fib)
    expect(page).to have_selector(%([class~="test-phrase-group"]), count: 3)
  end
end
