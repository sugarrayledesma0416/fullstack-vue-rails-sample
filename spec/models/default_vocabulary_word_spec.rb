describe DefaultVocabularyWord do
  let(:program) { create(:program) }
  let(:lesson) { create(:lesson) }
  let(:dv) { build(:default_vocabulary_word, lesson: lesson) }

  describe 'validation checking' do
    it 'has a valid factory' do
      dv.valid?
    end

    it 'requires a program ID' do
      dv = build(:default_vocabulary_word, program_id: nil)
      expect(dv).not_to be_valid
      expect(dv.errors[:program_id]).to contain_exactly('is required')
      expect(dv.errors[:program]).to contain_exactly('must exist')
    end

    it 'requires a lesson ID' do
      dv = build(:default_vocabulary_word, lesson_id: nil)
      expect(dv).not_to be_valid
      expect(dv.errors[:lesson_id]).to contain_exactly('is required')
      expect(dv.errors[:lesson]).to contain_exactly('must exist')
    end

    it 'requires a composite_dictionary_id' do
      dv = build(:default_vocabulary_word, composite_dictionary_id: nil)
      expect(dv).not_to be_valid
      expect(dv.errors[:composite_dictionary_id]).to contain_exactly(
        'is invalid', 'is required'
      )
    end

    it 'requires a topic' do
      dv = build(:default_vocabulary_word, topic: nil)
      expect(dv).not_to be_valid
      expect(dv.errors[:topic]).to contain_exactly('is required')
    end

    it 'requires a target' do
      dv = build(:default_vocabulary_word, target: nil)
      expect(dv).not_to be_valid
      expect(dv.errors[:target]).to contain_exactly('is required')
    end

    it 'requires a translation' do
      dv = build(:default_vocabulary_word, translation: nil)
      expect(dv).not_to be_valid
      expect(dv.errors[:translation]).to contain_exactly('is required')
    end

    it 'does not require a definition' do
      dv = create(:default_vocabulary_word, definition: nil)

      expect(dv).to be_valid
    end

    it 'returns audio_paths as an array' do
      dv = create(:default_vocabulary_word, lesson: lesson)

      expect(dv.reload.audio_paths).to eq(['foo.mp3', 'bar.mp3'])
    end

    it 'checks that the format of composite_dictionary_id is at least two ' \
       'numbers separated by colons' do
      dv = build(:default_vocabulary_word, composite_dictionary_id: '1')
      expect(dv).not_to be_valid
    end

    it 'allows duplicate composite_dictionary_id within different programs' do
      dv = create(:default_vocabulary_word, lesson: lesson)
      dv_2 = create(
        :default_vocabulary_word,
        composite_dictionary_id: dv.composite_dictionary_id
      )

      expect(dv_2).to be_valid
    end

    it 'checks that composite_dictionary_id is unique within a program' do
      dv = create(:default_vocabulary_word, lesson: lesson)
      dv_2 = build(
        :default_vocabulary_word,
        composite_dictionary_id: dv.composite_dictionary_id,
        program: dv.program
      )
      expect(dv_2).not_to be_valid
      expect(dv_2.errors[:composite_dictionary_id]).to contain_exactly(
        'has already been used'
      )
    end
  end

  describe '#ascii' do
    it 'transliterates target into ASCII if non-ASCII chars are present' do
      dv = build(:default_vocabulary_word, target: 'Ţĥè qùìćķ bŕòŵń fóx ĵúmpś ôvéŗ ťħê ļàźý ďõĝ.')
      expect(dv.ascii).to eq('The quick brown fox jumps over the lazy dog.')
    end

    it 'returns nil if target is all-ASCII' do
      dv = build(:default_vocabulary_word, target: 'The quick brown fox jumps over the lazy dog.')
      expect(dv.ascii).to be_nil
    end
  end
end
