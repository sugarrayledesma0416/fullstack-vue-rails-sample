describe VocabToolsWordsPresenter do
  describe '#payload' do
    let(:program) { create(:program) }
    let(:user) { create(:user) }
    let(:unit) { create(:unit, program: program) }
    let(:lesson) { create(:lesson, unit: unit) }
    let(:other_unit) { create(:unit, program: program) }
    let(:other_lesson) { create(:lesson, unit: other_unit) }
    let(:params) { { unit_id: unit.id } }
    let(:presenter) { described_class.new(user, program, params) }
    let(:program_settings) do
      instance_double(
        ProgramSettings,
        has_vocab_definition?: false,
        hide_translation?: false
      )
    end

    before do
      allow(ProgramSettings).to receive(:new).and_return(program_settings)
    end

    context 'when a unit_id param is specified' do
      it 'finds and returns default vocabulary for only the specified unit id', test_debt: true do
        # this failed on semaphore with seed 21872 but I can't get it to fail again
        # Error is:
        # Failure/Error: create(:default_vocabulary_word, composite_dictionary_id: '3:4:5', lesson: other_lesson)
        # ActiveRecord::RecordInvalid:
        # Validation failed: Composite dictionary has already been used
        default_vocabulary = create(:default_vocabulary_word, lesson: lesson)
        create(:default_vocabulary_word, composite_dictionary_id: '3:4:5', lesson: other_lesson)
        result = presenter.payload

        expect(result).to have_key(:words)
        words = result[:words]
        expect(words).to be_an(Array)
        expect(words.size).to eq(1)
        word = words.first
        expect(word).to eq(default_vocabulary)
      end

      it 'finds and returns user defined words only for the specified user and unit_id' do
        user_defined_word = create(:user_defined_word, program: program, user: user, lesson: lesson)
        # word from another user
        create(:user_defined_word, program: program, user: create(:user), lesson: lesson)
        # word in a different unit
        create(:user_defined_word, program: program, user: user, lesson: other_lesson)

        result = presenter.payload

        expect(result).to have_key(:words)
        words = result[:words]
        expect(words).to be_an(Array)
        expect(words.size).to eq(1)
        word = words.first
        expect(word).to eq(user_defined_word)
      end
    end

    context 'when a lesson_id param is specified' do
      let(:presenter) { described_class.new(user, program, { lesson_id: other_lesson.id } ) }
      it 'finds and returns default vocabulary for only the specified lesson id', test_debt: true do
        # this failed on semaphore with seed 35553 but I can't get it to fail again
        # Error is:
        # Failure/Error: create(:default_vocabulary_word, composite_dictionary_id: '3:4:5', lesson: other_lesson)
        # ActiveRecord::RecordInvalid:
        # Validation failed: Composite dictionary has already been used
        default_vocabulary = create(:default_vocabulary_word, lesson: other_lesson)
        create(:default_vocabulary_word, composite_dictionary_id: '3:4:5', lesson: lesson)
        result = presenter.payload

        expect(result).to have_key(:words)
        words = result[:words]
        expect(words).to be_an(Array)
        expect(words.size).to eq(1)
        word = words.first
        expect(word).to eq(default_vocabulary)
      end

      it 'finds and returns user defined words only for the specified user and lesson_id' do
        user_defined_word = create(:user_defined_word, program: program, user: user, lesson: other_lesson)
        # word from another user
        create(:user_defined_word, program: program, user: create(:user), lesson: other_lesson)
        # word in a different lesson
        create(:user_defined_word, program: program, user: user, lesson: lesson)

        result = presenter.payload

        expect(result).to have_key(:words)
        words = result[:words]
        expect(words).to be_an(Array)
        expect(words.size).to eq(1)
        word = words.first
        expect(word).to eq(user_defined_word)
      end
    end

    it 'instantiates a ProgramSettings instance with the current program' do
      expect(ProgramSettings).to receive(:new).with(program)

      result = presenter.payload
    end

    context 'when the current program is set to have definitions' do
      it 'sets vocab_has_definition to true in the metadata' do
        allow(program_settings).to receive(:has_vocab_definition?).and_return(true)
        allow(ProgramSettings).to receive(:new).and_return(program_settings)

        result = presenter.payload

        expect(result[:program_metadata][:vocab_has_definition]).to be_truthy
      end
    end

    context 'when the current program is set to not have definitions' do
      it 'sets vocab_has_definition to false in the metadata' do
        allow(program_settings).to receive(:has_vocab_definition?).and_return(false)
        allow(ProgramSettings).to receive(:new).and_return(program_settings)

        result = presenter.payload

        expect(result[:program_metadata][:vocab_has_definition]).to be_falsey
      end
    end

    context 'when the current program has language code as english' do
      it 'sets hide_translation to true in the metadata' do
        allow(program_settings).to receive(:hide_translation?).and_return(true)
        allow(ProgramSettings).to receive(:new).and_return(program_settings)

        result = presenter.payload

        expect(result[:program_metadata][:hide_translation]).to be_truthy
      end
    end

    context 'when the current program is not defined with english as its language' do
      it 'sets hide_translation to false in the metadata' do
        allow(program_settings).to receive(:hide_translation?).and_return(false)
        allow(ProgramSettings).to receive(:new).and_return(program_settings)

        result = presenter.payload

        expect(result[:program_metadata][:hide_translation]).to be_falsey
      end
    end
  end
end
