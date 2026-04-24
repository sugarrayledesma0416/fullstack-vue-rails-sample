feature 'Hyrbrid reading activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
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
  let(:activity) { create_hybrid_reading_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::HybridReading.new(activity, media_items) }
  let(:activity_url) { section_activity_path(0, activity) }

  let!(:media_items) do
    [
      create(:media_item_video, id: 5, filename: 'video_high_res.mp4'),
      create(:media_item_video, id: 2, filename: 'video_low_res.mp4'),
      create(:media_item_subtitle, id: 3, filename: 'foreign.vtt'),
      create(:media_item_subtitle, id: 14, filename: 'english.vtt'),
      create(:media_item_image, id: 6, filename: 'floating_image.jpg')
    ]
  end

  before do
    give_user_access_to_program(student, program)
    log_in_as(student)
    # student must be enrolled in a section with proper
    # course settings to see English subtitles.
    create(:active_enrollment, section: section, user: student)
  end

  def find_video_reference
    find('div.js-video-reference')['data-js-videotracks']
  end

  scenario 'Student visits a Hybrid Reading activity' do
    visit activity_url

    for_unsubmittable_page(activity_data) do
      expect_activity_shell_structure_to_be_complete
      expect(@page_object).to have_been_viewed

      # Test that activity with rubric xml
      # that is not in whitelisted rubric types doesn not show rubric link
      expect(page).not_to have_selector('.test-rubric-link')

      # Click the play button
      all('button.vjs-big-play-button').last.click

      # Check video src
      expect(find('video')['src']).to end_with(activity_data.video_filename)

      # Check descriptive audio
      expect(find('source.js-descriptive-video')['src']).to end_with(
        activity_data.descriptive_audio_filename
      )

      # Check subtitles/captions
      # The subtitle js expects json in the following structure:
      # data-js-videotracks= [
      #   {"kind":"descriptions","label":"descriptions","src":"https://url/name.mp4","type":"video/mp4"},
      #   {"kind":"captions","label":"Spanish","src":"https://url/name.vtt","srclang":"es"},
      #   {"kind":"captions","label":"English","src":"https://url/name.vtt","srclang":"en"}
      # ]
      expect(JSON.parse(find_video_reference)[1]['kind']).to eq('captions')
      expect(JSON.parse(find_video_reference)[1]['src']).to end_with(
        activity_data.foreign_subtitles_filename
      )
      expect(JSON.parse(find_video_reference)[2]['kind']).to eq('captions')
      expect(JSON.parse(find_video_reference)[2]['src']).to end_with(
        activity_data.english_subtitles_filename
      )

      # Check subtitles and descriptive audio buttons are visible
      caps_menu = page.all('div.vjs-subs-caps-button').last
      descrip_menu = page.all('div.vjs-descriptions-button').last
      caps_menu.assert_matches_style(visibility: 'visible')
      descrip_menu.assert_matches_style(visibility: 'visible')

      # Check video title
      expect(find('.test-video-title').text).to eq('This is a video title')

      # Check glosses
      find('a.js-gloss').click
      expect(find('div#tippy-1')['data-state']).to eq('visible')

      # Check floating image
      expect(find('img.test-floating-img')['src']).to end_with(
        activity_data.floating_image_filename
      )

      # Check subtitles
      expect(find('h2.test-subheading').text).to eq('This is a subheading')

      # Check paragraph
      expect(find('p.test-paragraph').text).to include('This is a paragraph.')

      # Check attempts remaining
      expect(find('.test-attempts-remaining').text).to start_with("VIEWED ON")
    end
  end
end
