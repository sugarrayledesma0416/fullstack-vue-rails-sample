feature 'Pronunciation example group references', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, family: 'vista_online_learning') }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity) { create_pronunciation_explore_activity(program) }
  let(:audio_media_item) { create(:media_item_audio, id: 1578) }

  before do
    create_example_audio_media_item(1)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
    visit section_activity_path(0, activity)
  end

  def pronunciation_references
    activity.content_object.reference.select { |ref| ref.type == 'pronunciation_example_group' }
  end

  def create_example_audio_media_item(id)
    create(
      :media_item_audio,
      filename: '/vocab_list_audio_1.mp3',
      id: id
    )
  end

  scenario 'I can preview a pronunciation explore activity' do
    expect(page).to have_selector(%([data-helpable-type="reference_pronunciation"]))
    expect(page).to have_selector(%([data-content-type="pronunciation_group"]))

    pronunciation_references.each do |reference|
      step 'I can see explanation text for each pronunciation group' do
        expect(page).to have_selector(
          '.test-pronunciation-explanation',
          text: reference.pronunciation_explanation.strip_tags,
          visible: :visible
        )
      end
    end

    step 'I can see a "Play All" button' do
      expect(page).to have_selector('.test-play-all', text: /Play All/)
    end

    purpose 'when "Play All" button is clicked it displays pause button' do
      step 'Click on "Play All" button' do
        find('.test-play-all').click
      end
      step 'I can see a "Pause" button' do
        expect(page).to have_selector('.test-pause', text: /Pause/)
      end
    end
  end

  scenario 'I can preview different reference types' do
    expect(page).to have_selector(
      %([data-content-type="reference_model_content"]),
      text: 'Text reference is here'
    )
    expect(page).to have_selector(%([data-helpable-type="reference_image"]))
    expect(page).to have_selector(%([data-helpable-type="reference_audio"]))
    expect(page).to have_selector(%([data-content-type="pronunciation_group"]))
  end
end
