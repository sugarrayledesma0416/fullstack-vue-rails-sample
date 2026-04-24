def create_vocab_list_v2_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'vocab_list_v2.xml'),
    program,
    grading_method: 'auto'
  )
end

feature 'Vocab list v2 activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  # It needs the ID because the xml fixture expects 8 media items with ids from 1 to 8
  # 4 images and 4 audios
  let!(:audio_media_items) do
    Array.new(4) do |i|
      id = i + 1
      create(:media_item_audio, id: id, filename: "vocab_list_audio_#{id}.mp3")
    end
  end

  let!(:image_media_items) do
    Array.new(4) do |i|
      id = i + 5 # Index starts at zero
      create(:media_item_image, id: id, filename: "multiple_choice_prompt_#{id}.gif")
    end
  end

  let(:activity) { create_vocab_list_v2_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::VocabListV2.new(activity, audio_media_items) }
  let(:activity_url) { section_activity_path(0, activity) }

  before do
    give_user_access_to_program(student, program)
    log_in_as(student)
  end

  def expect_vocab_chart_header_to_be_displayed(vocab_chart_data)
    from_vocab_chart(vocab_chart_data.chart_number) do |vocab_chart|
      expect(vocab_chart.title).to eq(vocab_chart_data.title)
      if vocab_chart_data.title_audio
        expect(vocab_chart.audio_source['src']).to end_with(vocab_chart_data.title_audio.filename)
      end
    end
  end

  def expect_all_vocab_chart_headers_to_be_displayed
    activity_data.vocab_charts.each do |vocab_chart|
      expect_vocab_chart_header_to_be_displayed(vocab_chart)
    end
  end

  def expect_vocab_group_target_to_be_visible
    for_each_vocab_chart_entry do |entry, entry_data|
      expect(entry.target).to eq(entry_data.target)
      entry_data.audio_paths.each.with_index(1) do |audio_data, audio_number|
        expect(entry.audio(audio_number)['src']).to end_with(audio_data)
      end
    end
  end

  def expect_vocab_group_target_to_be_hidden
    for_each_vocab_chart_entry do |entry, _entry_data|
      expect(entry.target).to eq('')
    end
  end

  def expect_vocab_group_translation_to_be_visible
    for_each_vocab_chart_entry do |entry, entry_data|
      expect(entry.translation).to eq(entry_data.translation)
    end
  end

  def expect_vocab_group_translation_to_be_hidden
    for_each_vocab_chart_entry do |entry, _entry_data|
      expect(entry.translation).to eq('')
    end
  end

  def for_each_vocab_chart_entry
    activity_data.vocab_charts.each do |vocab_chart|
      vocab_chart.entries.each do |entry_data|
        entry = from_vocab_chart(vocab_chart.chart_number).entry(entry_data.entry_number)
        yield entry, entry_data
      end
    end
  end

  scenario 'Student does a vocab list v2 activity' do
    visit activity_url

    for_unsubmittable_page(activity_data) do
      expect_activity_shell_structure_to_be_complete
      expect(@page_object).to have_been_viewed

      # Show target
      @page_object.select_vocab_list_language_visibility(:target)
      expect_all_vocab_chart_headers_to_be_displayed
      expect_vocab_group_target_to_be_visible
      expect_vocab_group_translation_to_be_hidden

      # Show translation
      @page_object.select_vocab_list_language_visibility(:translation)
      expect_all_vocab_chart_headers_to_be_displayed
      expect_vocab_group_target_to_be_hidden
      expect_vocab_group_translation_to_be_visible

      # Show both target and translation
      @page_object.select_vocab_list_language_visibility(:both)
      expect_all_vocab_chart_headers_to_be_displayed
      expect_vocab_group_target_to_be_visible
      expect_vocab_group_translation_to_be_visible
    end
  end
end
