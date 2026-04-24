describe VocabWord do
  let(:student) { create(:student) }

  describe 'validations' do
    it 'is invalid if user_id is blank' do
      vocab_word = build(:vocab_word, user_id: nil)
      vocab_word.valid?
      expect(vocab_word.errors[:user_id]).to eq(['is required'])
    end

    it 'is invalid if language is blank' do
      vocab_word = build(:vocab_word, language: nil)
      vocab_word.valid?
      expect(vocab_word.errors[:language]).to eq(['is required'])
    end

    it 'is invalid if target_word, base_word, or target_definition are blank' do
      vocab_word = build(
        :vocab_word,
        target_word: nil,
        base_word: nil,
        target_definition: nil
      )
      vocab_word.valid?
      expect(vocab_word.errors[:base]).to include(
        'Target word, base word, or definition must be entered.'
      )
    end

    it 'is valid when user_id, language, and a combination of the ' \
       'other attributes are present' do
      %i[target_word base_word target_definition].each do |attr|
        attrs = {
          target_word: nil,
          base_word: nil,
          target_definition: nil
        }.merge(attr => 'foo')

        vocab_word = create(:vocab_word, attrs)

        expect(vocab_word).to be_valid
      end
    end
  end

  describe '.find_or_build_vocab_words' do
    describe 'vocab program groups' do
      let(:vocab_group) { VocabProgramGroup.create! }
      let(:other_vocab_group) { VocabProgramGroup.create! }

      let(:program) { create(:program, vocab_program_group_id: vocab_group.id) }
      let(:program_without_access) { create(:program, vocab_program_group_id: vocab_group.id) }
      let(:program_in_other_program_group) do
        create(:program, vocab_program_group_id: other_vocab_group.id)
      end

      let!(:default_word_in_current_program_group) do
        create(
          :default_vocab_word,
          program_id: program.id,
          vocab_program_group_id: vocab_group.id
        )
      end

      let!(:default_word_in_program_without_access) do
        create(
          :default_vocab_word,
          program_id: program_without_access.id,
          vocab_program_group_id: vocab_group.id
        )
      end

      let!(:default_word_in_other_program_group) do
        create(
          :default_vocab_word,
          program_id: program_in_other_program_group.id,
          vocab_program_group_id: other_vocab_group.id
        )
      end

      let!(:word_in_current_program_group) do
        create(
          :vocab_word,
          program_id: program.id,
          user_id: student.id,
          vocab_program_group_id: vocab_group.id
        )
      end

      it 'returns a list of user defined vocab words for a user and program' do
        words = described_class.find_or_build_vocab_words(student, program)
        expect(words).to eql [
          word_in_current_program_group,
          default_word_in_current_program_group
        ]
      end

      it 'returns a list of vocab words and does not care the language if has program_id' do
        word_for_other_language_with_program_id = create(
          :vocab_word,
          language: 'de',
          program_id: program.id,
          user_id: student.id,
          vocab_program_group_id: vocab_group.id
        )

        words = described_class.find_or_build_vocab_words(student, program)
        expect(words).to match_array [
          word_for_other_language_with_program_id,
          word_in_current_program_group,
          default_word_in_current_program_group
        ]
      end

      it 'does not return words without program_id and diferent language than program' do
        word_for_other_language_with_no_program = create(
          :vocab_word,
          language: 'de',
          user_id: student.id,
          vocab_program_group_id: vocab_group.id
        )

        words = described_class.find_or_build_vocab_words(student, program)
        expect(words).not_to include(word_for_other_language_with_no_program)
      end

      it 'does not return words defined for programs with no access' do
        words = described_class.find_or_build_vocab_words(student, program)
        expect(words).not_to include(default_word_in_program_without_access)
      end

      it 'does not return words defined for another program group' do
        words = described_class.find_or_build_vocab_words(student, program)
        expect(words).not_to include(default_word_in_other_program_group)
      end

      it 'does not return archived words' do
        word_archived = create(
          :vocab_word,
          archived: true,
          program_id: program.id,
          user_id: student.id,
          vocab_program_group_id: vocab_group.id
        )

        words = described_class.find_or_build_vocab_words(student, program)
        expect(words).not_to include(word_archived)
      end

      it 'does not return words for another user' do
        word_for_another_user = create(
          :vocab_word,
          program_id: program.id,
          user_id: student.id + 1,
          vocab_program_group_id: vocab_group.id
        )

        words = described_class.find_or_build_vocab_words(student, program)
        expect(words).not_to include(word_for_another_user)
      end
    end

    it 'returns any vocab words added by the user for the current language' do
      # Words added by the student have a nil default_vocab_word_id because they
      # aren't copied from an existing default word.
      current_program = create(:program, language_code: 'es')
      other_program = create(:program, language_code: current_program.language_code)

      valid_word = create(:vocab_word, program_id: other_program.id, user_id: student.id)

      words = described_class.find_or_build_vocab_words(student, current_program)
      expect(words).to include(valid_word)
    end
  end

  describe '#serialize_to_json_for_student_and_language' do
    let(:student) { create(:student) }
    let(:vocab_program_group) { VocabProgramGroup.create! }
    let(:program) { create(:program, vocab_program_group_id: vocab_program_group.id) }
    let(:unit) { create(:unit, program: program, lessons: []) }
    let!(:lesson) { create(:lesson, unit: unit, rank: 1, use_type: 'Lesson') }
    let!(:another_lesson) { create(:lesson, unit: unit, rank: 2, use_type: 'Lesson') }
    let!(:invalid_lesson) { create(:lesson, unit: unit, rank: 3, use_type: 'ResourceLesson') }

    it 'generates a JSON representation of a set of vocab words' do
      vocab_word = create(:vocab_word,
                           vocab_program_group_id: vocab_program_group.id,
                           user_id: student.id,
                           program_id: program.id)
      create(:vocab_tag, vocab_word: vocab_word)

      activities_hash = JSON.parse(described_class.find_or_build_vocab_words(
        student,
        program
      ).to_json(include: :vocab_tags))

      lessons = [{
        program_name: program.title,
        id: lesson.id,
        label: nil,
        name: 'Lesson 1'
      },
                 {
        program_name: program.title,
        id: another_lesson.id,
        label: nil,
        name: 'Lesson 2'
      }]

      expected = {
        'language' => program.language_code,
        'activities' => activities_hash,
        'lessons' => lessons
      }.to_json
      results = described_class.serialize_to_json_for_student_and_language(student, program)
      expect(JSON.parse(results)).to eq(JSON.parse(expected))
    end
  end

  describe '#as_json' do
    it 'serializes recording_path' do
      recording = create(:recording)
      vocab_word = described_class.new
      allow(vocab_word).to receive(:recording).and_return(recording)
      expect(vocab_word.to_json['recording_path']).to eq(recording.recording_path)
    end
  end
end
