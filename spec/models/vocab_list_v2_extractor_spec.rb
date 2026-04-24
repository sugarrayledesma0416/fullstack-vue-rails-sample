describe VocabListV2Extractor do
  let(:program) { create(:program) }
  let(:lesson) { create(:lesson) }
  let(:activity) { create(:activity, lesson: lesson, activity_type: 'vocab_list_v2') }
  let(:content_object) { instance_double('ContentObject') }
  let(:audio) { create(:media_item_audio) }
  let(:audio_link) { instance_double('Linked Media', media_item: audio) }
  let(:vocab_chart) { instance_double('VocabChart', title: 'vc title', title_audio: audio_link) }

  let(:vocab_group) do
    instance_double(
      'VocabGroup',
      definition: 'vg definition',
      hint: 'vg hint',
      pinyin: 'vg pinyin',
      target: 'vg target',
      translation: 'vg translation'
    )
  end

  let(:dictionary_entry) do
    instance_double(
      'DictionaryEntry',
      audio: audio_link,
      id: 1,
      pinyin: 'de pinyin',
      target: 'de target'
    )
  end

  let(:vl_v2_extractor) { described_class.new(activity) }

  before do
    allow(activity).to receive(:program).and_return(program)
    allow(vocab_group).to receive(:dictionary_entries).and_return([dictionary_entry])
    allow(vocab_chart).to receive(:vocab_group).and_return([vocab_group])
    allow(content_object).to receive(:vocab_chart).and_return([vocab_chart])
    allow(activity).to receive(:content_object).and_return(content_object)
  end

  describe '.generate_vocabulary_for' do
    it 'creates a vocabulary from the vocabulary v2 activities' do
      expect(DefaultVocabularyWord.count).to eq 0
      activities = instance_double(ActiveRecord::Relation)
      allow(activities).to(
        receive(:where).with('activities.instructor_revision_id is null') .and_return([activity])
      )
      allow(Activity).to receive(:where).with(
        lesson_id: program.lessons,
        activity_type: 'vocab_list_v2'
      ) .and_return(activities)
      described_class.generate_vocabulary_for(program)
      results = DefaultVocabularyWord.where(program_id: program.id)
      expect(results.first.target).to eq(vocab_group.target)
    end

    it 'does not fail if the program has no vocabulary activities' do
      # no_actgccivity = Activity.destroy
      Activity.destroy(activity.id)
      expect { described_class.generate_vocabulary_for(program) }.not_to raise_error
    end
  end

  describe '#flashcards' do
    it 'returns a hash of default vocab words' do
      flashcards = vl_v2_extractor.flashcards
      expect(flashcards).to be_a(Hash)
      expect(flashcards.values.first).to be_a(DefaultVocabularyWord)
      expect(flashcards.values.first.target).to eq(vocab_group.target)
    end
  end

  describe '#vtext' do
    it 'returns array vocab group and dictionary entry data rows' do
      allow(vocab_group).to receive(:dictionary_entries).and_return([dictionary_entry])
      allow(vocab_chart).to receive(:vocab_group).and_return([vocab_group])
      allow(content_object).to receive(:vocab_chart).and_return([vocab_chart])
      allow(activity).to receive(:content_object).and_return(content_object)

      vtext = vl_v2_extractor.vtext
      expect(vtext.first[:target_word]).to eql('vc title')
      expect(vtext.last[:target_word]).to eql('de target')
    end
  end
end
