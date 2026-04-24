feature 'Short clips activities', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, family: 'vista_online_learning') }

  let(:activity) { create_short_clips_activity_with_phrase_chart(program) }

  let!(:character_list_images) do
    Array.new(2) do |i|
      create(
        :media_item_image,
        id: (700 + i),
        filename: "unit#{i + 1}_thumbnail.png"
      )
    end
  end

  def create_clip_images
    Array.new(2) do |i|
      create(
        :media_item_image,
        id: (702 + i),
        width: 247,
        height: 100,
        filename: "unit#{i + 3}_thumbnail.png"
      )
    end
  end

  def create_clip_videos
    Array.new(2) do |i|
      create(
        :media_item_video,
        id: (704 + i),
        width: 400,
        height: 320,
        filename: 'video_low_res.mp4'
      )
    end
  end

  def character_list
    activity.content_object.references[0].characters
  end

  def validate_clip_and_transcript(clip)
    step 'I can see clip video' do
      expect(page).to have_css("video[src*='#{clip.video.media_item.filename}']")
    end

    step 'I can see clip transcript' do
      validate_transcript(clip.transcript)
    end
  end

  def validate_transcript(transcripts)
    transcripts.each_with_index do |transcript, i|
      if transcript.is_a?(Hash)
        expect(page).to have_selector(".test-speaker-#{i}", text: transcript[:speaker])
        expect(page).to have_selector(".test-dialog-#{i}", text: transcript[:dialog])
      else
        expect(page).to have_selector(".test-stage-direction-#{i}", text: transcript)
      end
    end
  end

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    create_clip_images
    create_clip_videos

    log_in_as(instructor)
  end

  xscenario 'I can see a short clips activity' do
    visit section_activity_path(0, activity)

    purpose 'I can see a character reference' do
      within('.test-character-list-reference') do
        step 'I can see character list heading "Personajes"' do
          expect(page).to have_selector('.test-reference-header', text: 'Personajes')
        end

        step 'I can see list of each character`s name and image' do
          character_list.each_with_index do |character, i|
            within(".test-character-#{i}") do
              expect(page).to have_css("img[src*='#{character_list_images[i].filename}']")
              expect(page).to have_selector(".test-character-name-#{i}", text: character.name)
            end
          end
        end
      end
    end

    purpose 'I can see episode summary' do
      step 'I can see heading "Episode Summary"' do
        expect(page).to have_selector('.test-episode-summary-header', text: 'Episode Summary')
      end

      step 'I can see episode summary description' do
        expect(page).to have_selector(
          '.test-episode-summary-description',
          text: activity.content_object.episode_synopsis
        )
      end
    end

    purpose 'I can see a list of clips' do
      within('.test-clip-list-container') do
        activity.content_object.clips.each_with_index do |clip, i|
          within(".test-clip-item-wrapper-#{i}") do
            step 'I can see clip image' do
              expect(page).to have_css("img[src*='#{clip.image.media_item.filename}']")
            end

            step 'I can see clip video' do
              expect(page).to have_selector('.test-clip-name', text: "Clip #{i + 1}")
            end
          end
        end
      end
    end

    purpose 'I can see first clip video with transcription' do
      within('.test-video-transcript-container') do
        step 'I can see first clip video and transcript' do
          validate_clip_and_transcript(activity.content_object.clips[0])
        end
      end
    end

    purpose 'I can change the clip video by clicking previous and next buttons' do
      step 'Click the "Next" button' do
        find('.test-next-clip-btn').click
      end

      step 'I can see secpnd clip video and transcript' do
        validate_clip_and_transcript(activity.content_object.clips[1])
      end

      step 'Click the "Previous" button' do
        find('.test-prev-clip-btn').click
      end

      step 'I can see first clip video and transcript' do
        validate_clip_and_transcript(activity.content_object.clips[0])
      end
    end

    purpose 'I can change the clip video by selecting a clip from the list' do
      step 'Click on second clip from the clip list' do
        find('.test-clip-list-container .test-clip-item-wrapper-1').click
      end

      step 'I can see secpnd clip video and transcript' do
        validate_clip_and_transcript(activity.content_object.clips[1])
      end
    end

    purpose 'I can see a phrase chart side bar reference' do
      expect(page).to have_selector(%([data-helpable-type="reference_phrase_chart"]))
    end
  end
end
