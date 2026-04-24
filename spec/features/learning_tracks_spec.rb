feature 'Learning tracks activities', test_debt: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, :vista_online_learning => true) }
  let(:course) { create(:course, :owner => instructor, :program => program) }
  let(:section) { create(:section, :course => course, :instructor => instructor) }
  let(:xml_filename) { 'xml/watch_and_repeat.xml' }
  let(:avatar) { double('avatar', thumbnail_path: '/images/default-thumbnail.gif') }
  let(:activity) { create_activity(program, xml_filename) }

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
    allow(Avatar).to receive(:new).and_return(avatar)
    visit section_activity_path(0, activity)
  end

  scenario 'I can see a learning engine activity with a watch_and_repeat checkpoint', :js => true do
    pending "Fix this test"
    expect(page).to have_selector(%(div.cp-type), text: 'Watch and repeat')
  end
end
