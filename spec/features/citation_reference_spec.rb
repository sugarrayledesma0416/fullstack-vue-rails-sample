feature 'Reference activity with citation' do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, family: 'vista_online_learning') }
  let(:course) { create(:course, :owner => instructor, :program => program) }
  let(:section) { create(:section, :course => course, :instructor => instructor) }
  let(:reference_activity) { create_reference_activity_with_citation_reference(program) }
  let!(:media_item_image) { create(:media_item_image, :id => 5) }

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'Instructor sees an activity with citation reference' do
    visit section_activity_path(0, reference_activity)
    expect(page).to have_selector('[data-content-type="citation"]', text: 'This is a citation')
  end

end
