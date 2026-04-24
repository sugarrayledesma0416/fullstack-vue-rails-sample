feature 'Pronunciation example group references' do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, family: 'vista_online_learning') }
  let(:course) { create(:course, :owner => instructor, :program => program) }
  let(:section) { create(:section, :course => course, :instructor => instructor) }
  let(:short_clips_activity) { create_short_clips_activity_with_phrase_chart(program) }
  let(:reference_activity) { create_reference_activity_with_phrase_chart(program) }
  let!(:video_media_item_1) { create(:media_item_video, id: 704, width: 400, height: 320) }
  let!(:video_media_item_2) { create(:media_item_video, id: 705, width: 400, height: 320) }
  let!(:image_media_item_1) { create(:media_item, id: 702, media_type: 'image', height: 100) }
  let!(:image_media_item_2) { create(:media_item, id: 703, media_type: 'image', height: 100) }

  before do
    allow(MediaItem).to receive(:find).and_return(build_stubbed(:media_item))
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  scenario 'I can preview a short clips activity that contains phrase chart references' do
    visit section_activity_path(0, short_clips_activity)
    page_should_contain_phrase_chart_content(page)
  end

  scenario 'I can preview a reference activity that contains phrase chart references' do
    visit section_activity_path(0, reference_activity)
    page_should_contain_phrase_chart_content(page)
  end

  def page_should_contain_phrase_chart_content(page)
    expect(page).to have_selector(%([data-helpable-type="reference_phrase_chart"]))
    expect(page).to have_selector(%([data-content-type="phrase_group"]))
    expect(page).to have_selector(%([data-content-type="phrase_group_header"]), text: 'Talking with hotel personnel')
  end
end
