feature 'Audio Prompt In Custom Assessment', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  include Capybara::Angular::DSL
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:assessment_strand) { create(:toc_entry) }
  let(:course) do
    create(:course,
           owner: instructor,
           program:,
           allows_help_requests: true,
           allows_review_requests: true,
           allow_audio_transcripts: true)
  end
  let(:section) { create(:section, course:, instructor:) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, toc_entries: [assessment_strand], unit:) }
  let(:activity) do
    create(:json_activity_with_audio_prompt, title: 'Mid-Unit Assessment', lesson:)
  end

  let(:audio_media_item) do
    create(:media_item_audio, id: '7723', filename: 'vocab_list_audio_1.mp3', transcript: 'Sample Audio Transcript')
  end

  let!(:audio_media_link) do
    MediaLink.new(desired_media_item_id: audio_media_item.id)
  end

  before do
    allow_any_instance_of(ProgramSettings).to receive(:has_audio_transcripts?)
      .and_return(true)
    create(
      :active_enrollment,
      section:,
      user: student
    )
    give_user_access_to_program(student, program)
  end

  scenario 'when logged in as student' do
    step 'I can log in as a student' do
      log_in_as(student)
    end

    purpose 'I can see audio prompts on questions' do
      step 'I can visit the activity show page' do
        visit section_activity_path(section.id, activity.id)
      end

      step 'I can see audio prompt on open ended question' do
        expect(page).to have_selector(
          '.test-open-ended-questions .test-question_02-audio-transcript .test-play-audio'
        )
      end

      step 'I can see the audio transcript text for open ended question' do
        expect(page).to have_selector(
          '.test-open-ended-questions .test-question_02-audio-transcript .test-transcript-disclosure__header'
        )
      end

      step 'I can see the audio transcript text for open ended question in Model Reference' do
        expect(page).to have_selector(
          '.test-reference-model .test-reference-model-audio .test-transcript-disclosure__header'
        )
      end

      step 'I can see audio prompt on fill in the blank question' do
        expect(page).to have_selector(
          '.test-fill-in-the-blanks-questions .test-question_02-whole-question .test-play-audio'
        )
      end

      step 'I can see the audio transcript text for fill in the blank question' do
        expect(page).to have_selector(
          '.test-fill-in-the-blanks-questions .test-question_02-whole-question .test-transcript-disclosure__header'
        )
      end

      step 'I can see audio prompt on true false question' do
        expect(page).to have_selector(
          '.test-multiple-choice .test-question_03-audio-transcript .test-play-audio'
        )
      end

      step 'I can see the audio transcript text for true false question' do
        expect(page).to have_selector(
          '.test-multiple-choice .test-question_03-audio-transcript .test-transcript-disclosure__header'
        )
      end

      step 'I can see audio prompt on drop down question' do
        expect(page).to have_selector(
          '.test-dropdown-questions .test-question_02-whole-question .test-play-audio'
        )
      end

      step 'I can see the audio transcript text for drop down question' do
        expect(page).to have_selector(
          '.test-dropdown-questions .test-question_02-whole-question .test-transcript-disclosure__header'
        )
      end

      step 'I can see audio prompt on composition question' do
        expect(page).to have_selector(
          '.test-composition .test-question_01-audio-transcript .test-play-audio'
        )
      end

      step 'I can see the audio transcript text for composition question' do
        expect(page).to have_selector(
          '.test-composition .test-question_01-audio-transcript .test-transcript-disclosure__header'
        )
      end

      step 'I can see audio prompt on multiple answer question' do
        expect(page).to have_selector(
          '.test-multiple-answer .test-question_03 .test-play-audio'
        )
      end

      step 'I can see the audio transcript text for question prompt in Multiple Answer' do
        expect(page).to have_selector(
          '.test-multiple-answer .test-question_03 .test-transcript-disclosure__header'
        )
      end

      step 'I can see audio prompt on multiple answer choice' do
        expect(page).to have_selector(
          '.test-question_03_choice_01_audio_transcript .test-play-choice-audio'
        )
      end
    end
  end
end
