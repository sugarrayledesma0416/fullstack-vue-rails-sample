def create_multi_type_with_oe_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'multi_type_with_oe.xml'),
    program,
    grading_method: 'auto'
  )
end

def find_video_reference
  find('div.js-video-reference')['data-js-videotracks']
end

feature 'Multi type activity video reference', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:course) do
    create(:course,
           owner: instructor,
           program: program,
           video_subtitle_languages: 'foreign_and_english')
  end
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity) { create_multi_type_with_oe_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::MultiType.new(activity, media_items) }
  let(:activity_url) { section_activity_path(0, activity) }
  let!(:media_items) do
    [
      create(:media_item_video, id: 5, filename: 'video_high_res.mp4'),
      create(:media_item_video, id: 2, filename: 'video_low_res.mp4'),
      create(:media_item_subtitle, id: 3, filename: 'foreign.vtt'),
      create(:media_item_subtitle, id: 14, filename: 'english.vtt')
    ]
  end

  before do
    give_user_access_to_program(student, program)
    log_in_as(student)
    create(:active_enrollment, section: section, user: student)
  end

  scenario 'As a user, I can see subtitle and descriptive audio in a video reference' do
    visit activity_url

    for_preview_page(activity_data) do
      # Click the play button
      find('button.vjs-big-play-button').click

      # Check video src
      expect(find('video')['src']).to end_with('video_high_res.mp4')

      # Check descriptive audio
      expect(find('source.js-descriptive-video')['src']).to end_with('video_low_res.mp4')

      # Check subtitles/captions
      # The subtitle js expects json in the following structure:
      # data-js-videotracks= [
      #   {"kind":"descriptions","label":"descriptions","src":"https://url/name.mp4","type":"video/mp4"},
      #   {"kind":"captions","label":"Spanish","src":"https://url/name.vtt","srclang":"es"},
      #   {"kind":"captions","label":"English","src":"https://url/name.vtt","srclang":"en"}
      # ]
      expect(JSON.parse(find_video_reference)[1]['kind']).to eq('captions')
      expect(JSON.parse(find_video_reference)[1]['src']).to end_with('foreign.vtt')
      expect(JSON.parse(find_video_reference)[2]['kind']).to eq('captions')
      expect(JSON.parse(find_video_reference)[2]['src']).to end_with('english.vtt')

      # Check subtitles and descriptive audio buttons are visible
      caps_menu = page.find('div.vjs-subs-caps-button')
      descrip_menu = page.find('div.vjs-descriptions-button')
      caps_menu.assert_matches_style(visibility: 'visible')
      descrip_menu.assert_matches_style(visibility: 'visible')
    end
  end
end
