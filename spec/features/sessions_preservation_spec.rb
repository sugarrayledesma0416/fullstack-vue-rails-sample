feature 'Sessions perseverance', test_debt: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, :vista_online_learning => true) }
  let(:course) { create(:course, :owner => instructor, :program => program) }
  let(:section) { create(:section, :course => course, :instructor => instructor) }
  let(:activity) { create_fill_in_the_blanks_activity_with_model(program) }


  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  it 'preserves user session across pages' do
    visit section_activity_path(0, activity)
    expect(page).to have_selector('#activity_shell')
  end

  it 'JS - preserves user session across pages', js: true do
    visit section_activity_path(0, activity)
    expect(page).to have_selector('#activity_shell')
  end
end
