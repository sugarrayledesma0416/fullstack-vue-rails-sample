#encoding: utf-8
describe DefaultVocabularyWordSerializer do

  let(:lesson) { create(:lesson) }

  it 'renders the correct JSON' do
    default_vocabulary_word = build(:default_vocabulary_word, lesson_id: lesson.id)
    expected = {
      target: 'pasaporte',
      definition: 'a passport',
      translation: 'passport',
      audio_paths: ['foo.mp3', 'bar.mp3'],
      lesson_id: lesson.id,
      pinyin: nil,
      topic: 'Travel'
    }
    expect(described_class.new(default_vocabulary_word).as_json).to eq(expected)
  end

  it 'includes an ascii attribute if the target has non-ASCII characters' do
    default_vocabulary_word = build(:default_vocabulary_word, lesson_id: lesson.id, target: 'föö')
    expected = {
      target: 'föö',
      definition: 'a passport',
      translation: 'passport',
      audio_paths: ['foo.mp3', 'bar.mp3'],
      lesson_id: lesson.id,
      topic: 'Travel',
      pinyin: nil,
      ascii: 'foo'
    }
    expect(described_class.new(default_vocabulary_word).as_json).to eq(expected)
  end

end
