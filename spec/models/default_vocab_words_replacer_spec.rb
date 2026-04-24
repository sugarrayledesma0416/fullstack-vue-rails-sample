#  encoding: utf-8

describe DefaultVocabWordsReplacer, test_debt: true do
  # Flagging test debt because this is for a rake task that is not in
  # active use.
  let(:program) { create(:program_with_lessons, language_code: 'es') }

  describe '#replace' do
    context 'when headers are invalid' do
      it 'raises an error when required headers are incomplete' do
        invalid_csv_path = create_csv_temp_file("word,definition,English translation,tags\ncafé,,brown,Lección_6,Viva;Lección_6;¡De compras!;Los colores;adjective")
        expect { DefaultVocabWordsReplacer.new(invalid_csv_path, program.id).replace }.to raise_error "Required file headers missing in CSV file: lesson."
      end

      it 'does not raise an error when file has extra headers' do
        invalid_csv_path = create_csv_temp_file("word,worder,definition,English translation,lesson,tags, disambiguation\ncafé,,brown,Lección_6,Viva;Lección_6;¡De compras!;Los colores;adjective")
        vocab_replacer = DefaultVocabWordsReplacer.new(invalid_csv_path, program.id)
        allow(vocab_replacer).to receive(:lesson_id_for).and_return(1)
        expect { vocab_replacer.replace }.not_to raise_error
      end
    end

    context 'when file headers are valid' do
      let(:target_word) { 'café' }
      let(:base_word) { 'brown' }
      let(:vocab_tags) { 'Viva;Lección_6;¡De compras!;Los colores;adjective' }

      before do
        @valid_csv_path = create_csv_temp_file("word,definition,English translation,lesson,tags\n#{target_word},,#{base_word},Lección_1,#{vocab_tags}")
      end

      it 'does not raise an error when file has valid headers' do
        expect { DefaultVocabWordsReplacer.new(@valid_csv_path, program.id).replace }.not_to raise_error
      end

      it 'deletes all existing default vocab words for the program' do
        existing_vocab_word = create(:default_vocab_word, program: program)
        DefaultVocabWordsReplacer.new(@valid_csv_path, program.id).replace
        expect(DefaultVocabWord.where(program_id: program.id)).not_to include existing_vocab_word
      end

      it 'creates default vocab words and tags from the csv file' do
        DefaultVocabWordsReplacer.new(@valid_csv_path, program.id).replace
        results = DefaultVocabWord.where(program_id: program.id)
        expect(results.count).to eq(1)
        new_vocab_word = results.first
        expect(new_vocab_word.target_word).to eq(target_word.to_utf8)
        expect(new_vocab_word.base_word).to eq(base_word.to_utf8)
        vocab_tags_array = vocab_tags.split(';')
        created_vocab_tags_names = new_vocab_word.vocab_tags.map(&:name)
        vocab_tags_array.each do |vocab_tag|
          expect(created_vocab_tags_names).to include vocab_tag.to_utf8
        end
      end

      it 'loads the techEditorial CSV files without problems' do
        file_path = File.join(Rails.root, 'spec', 'fixtures', 'Espaces3e_My_Vocab.csv')
        vocab_replacer = DefaultVocabWordsReplacer.new(file_path, program.id)
        allow(vocab_replacer).to receive(:lesson_id_for).and_return(1)
        vocab_replacer.replace
        expect(DefaultVocabWord.first.target_word).to eq('À bientôt.')
      end

      context 'when setting the lesson id' do
        let(:lesson_1) { program.units[0].lessons.first }
        let(:lesson_2) { program.units[1].lessons.first }

        it 'sets the correct lesson id for new vocab words when lessson number is a number' do
          lesson_1.update(name: "Leccion 10 | Hola")
          lesson_2.update(name: "Leccion 1 | Adios")
          DefaultVocabWordsReplacer.new(@valid_csv_path, program.id).replace
          expect(DefaultVocabWord.where(program_id: program.id).first.lesson_id).to eq(lesson_2.id)
        end

        it 'sets the correct lesson id for new vocab words when lessson number includes a letter' do
          csv_path = create_csv_temp_file("word,definition,English translation,lesson,tags\n#{target_word},,#{base_word},Lección_2A,#{vocab_tags}")
          lesson_1.update(name: "Leccion 2B | Hola")
          lesson_2.update(name: "Leccion 2A | Adios")
          DefaultVocabWordsReplacer.new(csv_path, program.id).replace
          expect(DefaultVocabWord.where(program_id: program.id).first.lesson_id).to eq(lesson_2.id)
        end

        it 'sets the correct lesson id for each vocab word' do
          content_string = "word,definition,English translation,lesson,tags\n" +
                           "#{target_word},,#{base_word},Lección_2A,#{vocab_tags}\n" +
                           "target,,base,Lección_3A,tags"
          csv_path = create_csv_temp_file(content_string)
          lesson_1.update(name: "Leccion 3A | Hola")
          lesson_2.update(name: "Leccion 2A | Adios")
          DefaultVocabWordsReplacer.new(csv_path, program.id).replace
          vocab_words = DefaultVocabWord.where(program_id: program.id)
          expect(vocab_words.detect{ |word| word.base_word == base_word}.lesson_id).to eq(lesson_2.id)
          expect(vocab_words.detect{ |word| word.base_word == 'base'}.lesson_id).to eq(lesson_1.id)
        end

        context 'when lesson column specifies more than one lesson' do
          it "sets the lowest rank lesson's id for the word" do
            csv_path = create_csv_temp_file("word,definition,English translation,lesson,tags\n#{target_word},,#{base_word},Leccion_2;Leccion_1,#{vocab_tags}")
            lesson_1.update(name: "Leccion 2 | Hola")
            lesson_2.update(name: "Leccion 1 | Adios")
            DefaultVocabWordsReplacer.new(csv_path, program.id).replace
            vocab_words = DefaultVocabWord.where(program_id: program.id)
            expect(vocab_words.detect{ |word| word.base_word == base_word}.lesson_id).to eq(lesson_2.id)
          end

          context 'when book is german' do
            it "uses the 'B' lesson of the specified lesson number" do
              csv_path = create_csv_temp_file("word,definition,English translation,lesson,tags\n#{target_word},,#{base_word},Lektion_4;Lektion_1,#{vocab_tags}")
              lesson_1.update(name: "Lektion 1B | Hola")
              lesson_2.update(name: "Lektion 4B | Adios")
              DefaultVocabWordsReplacer.new(csv_path, program.id).replace
              vocab_words = DefaultVocabWord.where(program_id: program.id)
              expect(vocab_words.detect{ |word| word.base_word == base_word}.lesson_id).to eq(lesson_1.id)
            end
          end
        end

        context 'when book is german' do
          it "associates the word to the 'B' lesson of the specified lesson number" do
            csv_path = create_csv_temp_file("word,definition,English translation,lesson,tags\n#{target_word},,#{base_word},Lektion_2;Lektion_1,#{vocab_tags}")
            lesson_1.update(name: "Lektion 1A | Hola")
            lesson_2.update(name: "Lektion 1B | Adios")
            DefaultVocabWordsReplacer.new(csv_path, program.id).replace
            vocab_words = DefaultVocabWord.where(program_id: program.id)
            expect(vocab_words.detect{ |word| word.base_word == base_word}.lesson_id).to eq(lesson_2.id)
          end
        end

        context 'when lesson is not found' do
          it 'raises an informative error' do
            missing_lesson = 'Lección_2A'
            csv_path = create_csv_temp_file("word,definition,English translation,lesson,tags\n#{target_word},,#{base_word},#{missing_lesson},#{vocab_tags}")
            lesson_1.update(name: "Leccion 10 | Hola")
            expect{ DefaultVocabWordsReplacer.new(csv_path, program.id).replace }.to raise_error "#{missing_lesson.to_utf8} was not found for #{target_word.to_utf8} in #{program.title}"
          end
        end
      end
    end
  end

  def create_csv_temp_file(csv_content)
    file_path = File.join('tmp', 'temp_csv.csv')
    File.open(file_path, "w") { |f| f.write csv_content }
    @recycle_bin << file_path
    file_path
  end
end
