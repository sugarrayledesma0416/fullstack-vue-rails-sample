describe QuestionBanks::MultipleChoiceBuilder do
  let(:choices) { 2 }
  let(:direction_line) { 'my dl' }
  let(:title) { 'my title' }

  let(:exam_reference_class) do
    MaestroActivityEngine::ActivityContent::Reference::Exam
  end

  let(:exam_reference) { instance_double(exam_reference_class) }

  let(:row_with_2_choices) do
    # order of keys must match column order of csv file
    {
      prompt: 'row with 2 choices',
      correct_answer: 'a',
      distractor_1: 'b'
    }
  end

  let(:row_with_3_choices) do
    # order of keys must match column order of csv file
    {
      prompt: 'row with 2 choices',
      correct_answer: 'a',
      distractor_1: 'b',
      distractor_2: 'c'
    }
  end

  let(:row_with_4_choices) do
    # order of keys must match column order of csv file
    {
      prompt: 'row with 2 choices',
      correct_answer: 'a',
      distractor_1: 'b',
      distractor_2: 'c',
      distractor_3: 'd'
    }
  end

  let(:lines) do
    [CSV::Row.new(row_with_2_choices.keys, row_with_2_choices.values)]
  end

  let(:attrs) do
    {
      choices: choices,
      exam_reference: exam_reference,
      lines: lines,
      metadata: {
        choice_lang: 'es',
        direction_line: direction_line,
        dl_lang: 'en',
        language_code: 'es',
        prompt_lang: 'es',
        title: title
      }
    }
  end

  let(:builder) { described_class.new(**attrs) }

  describe '#content_object' do
    let(:activity_class) do
      MaestroActivityEngine::ActivityContent::MultipleChoiceContent
    end
    let(:content) { instance_double(activity_class) }

    before do
      allow(activity_class).to receive(:from_csv_hash).and_return(content)
    end

    it 'calls .from_csv_hash on the MultipleChoiceContent class, passing in ' \
       'the specified direction_line, exam_reference, and title' do
      builder.content_object

      expect(activity_class).to have_received(:from_csv_hash).with(
        hash_including(
          direction_line: direction_line,
          exam_reference: exam_reference,
          title: title
        )
      )
    end

    it 'specifies an item data entry for each line, with a prompt, 1-indexed' \
       'number, and an array of hashes of choice data' do
      builder.content_object

      expect(activity_class).to have_received(:from_csv_hash).with(
        hash_including(
          item_data: [
            {
              choices: contain_exactly(
                { is_correct: true, text: 'a' },
                { is_correct: false, text: 'b' }
              ),
              number: 1,
              prompt: 'row with 2 choices'
            }
          ]
        )
      )
    end

    it 'handles markdown for bold and italics in the prompt' do
      row_with_2_choices[:prompt] = 'normal **bold** normal __italic__'
      expected_prompt = 'normal <b>bold</b> normal <i>italic</i>'

      builder.content_object

      expect(activity_class).to have_received(:from_csv_hash).with(
        hash_including(
          item_data: [
            {
              choices: contain_exactly(
                { is_correct: true, text: 'a' },
                { is_correct: false, text: 'b' }
              ),
              number: 1,
              prompt: expected_prompt
            }
          ]
        )
      )
    end

    context 'when the prompt contains double plus signs,' do
      context 'when the prompt language is english,' do
        before do
          row_with_2_choices[:prompt] = 'english ++foreign1++ english ' \
                                        '++foreign2++ english'
          attrs[:metadata][:prompt_lang] = 'en'
        end

        it 'replaces double plus signs in the prompt with language span ' \
           'tags specifying the target language' do
          expected_prompt = 'english <span lang="es"><b>foreign1</b></span> ' \
                            'english <span lang="es"><b>foreign2</b></span> ' \
                            'english'

          builder.content_object

          expect(activity_class).to have_received(:from_csv_hash).with(
            hash_including(
              item_data: [
                {
                  choices: contain_exactly(
                    { is_correct: true, text: 'a' },
                    { is_correct: false, text: 'b' }
                  ),
                  number: 1,
                  prompt: expected_prompt
                }
              ]
            )
          )
        end
      end

      context 'when the prompt language is foreign,' do
        before do
          row_with_2_choices[:prompt] = 'foreign ++english1++ foreign ' \
                                        '++english2++ foreign'
          attrs[:metadata][:prompt_lang] = 'es'
        end

        it 'replaces double plus signs in the prompt with language span ' \
           'tags specifying english' do
          expected_prompt = 'foreign <span lang="en"><i>english1</i></span> ' \
                            'foreign <span lang="en"><i>english2</i></span> ' \
                            'foreign'

          builder.content_object

          expect(activity_class).to have_received(:from_csv_hash).with(
            hash_including(
              item_data: [
                {
                  choices: contain_exactly(
                    { is_correct: true, text: 'a' },
                    { is_correct: false, text: 'b' }
                  ),
                  number: 1,
                  prompt: expected_prompt
                }
              ]
            )
          )
        end
      end
    end

    it 'handles markdown for bold and italics in the choices' do
      row_with_2_choices[:correct_answer] = 'answer **bold me** normal ' \
                                            '__ital me__ normal'
      row_with_2_choices[:distractor_1] = 'distractor **bold me** normal ' \
                                          '__ital me__ normal'

      expected_answer = 'answer <b>bold me</b> normal <i>ital me</i> normal'
      expected_distractor = 'distractor <b>bold me</b> normal <i>ital me</i> normal'

      builder.content_object

      expect(activity_class).to have_received(:from_csv_hash).with(
        hash_including(
          item_data: [
            {
              choices: contain_exactly(
                { is_correct: true, text: expected_answer },
                { is_correct: false, text: expected_distractor }
              ),
              number: 1,
              prompt: 'row with 2 choices'
            }
          ]
        )
      )
    end

    context 'when the choices contain double plus signs,' do
      context 'when the choice language is english,' do
        before do
          row_with_2_choices[:correct_answer] = 'answer ++foreign1++ english ' \
                                                '++foreign2++ english'
          row_with_2_choices[:distractor_1] = 'distractor ++foreign1++ english ' \
                                              '++foreign2++ english'
          attrs[:metadata][:choice_lang] = 'en'
        end

        it 'replaces double plus signs in the choices with language span ' \
           'tags specifying the target language' do
          expected_answer = 'answer <span lang="es"><b>foreign1</b></span> ' \
                            'english <span lang="es"><b>foreign2</b></span> ' \
                            'english'
          expected_distractor = 'distractor <span lang="es"><b>foreign1</b></span> ' \
                                'english <span lang="es"><b>foreign2</b></span> ' \
                                'english'

          builder.content_object

          expect(activity_class).to have_received(:from_csv_hash).with(
            hash_including(
              item_data: [
                {
                  choices: contain_exactly(
                    { is_correct: true, text: expected_answer },
                    { is_correct: false, text: expected_distractor }
                  ),
                  number: 1,
                  prompt: 'row with 2 choices'
                }
              ]
            )
          )
        end
      end

      context 'when the choice language is foreign,' do
        before do
          row_with_2_choices[:correct_answer] = 'answer ++english1++ spanish ' \
                                                '++english2++ spanish'
          row_with_2_choices[:distractor_1] = 'distractor ++english1++ spanish ' \
                                              '++english2++ spanish'
          attrs[:metadata][:choice_lang] = 'es'
        end

        it 'replaces double plus signs in the choices with language span ' \
           'tags specifying english' do
          expected_answer = 'answer <span lang="en"><i>english1</i></span> ' \
                            'spanish <span lang="en"><i>english2</i></span> spanish'
          expected_distractor = 'distractor <span lang="en"><i>english1</i></span> ' \
                                'spanish <span lang="en"><i>english2</i></span> spanish'

          builder.content_object

          expect(activity_class).to have_received(:from_csv_hash).with(
            hash_including(
              item_data: [
                {
                  choices: contain_exactly(
                    { is_correct: true, text: expected_answer },
                    { is_correct: false, text: expected_distractor }
                  ),
                  number: 1,
                  prompt: 'row with 2 choices'
                }
              ]
            )
          )
        end
      end
    end

    it 'returns the generated content instance' do
      expect(builder.content_object).to eq(content)
    end
  end

  describe '#valid?' do
    context 'when the "prompt" header is missing,' do
      before do
        row_with_2_choices.delete(:prompt)
      end

      it 'sets an error' do
        builder.valid?

        expect(builder.errors).to contain_exactly(
          "required column header 'prompt' was not found"
        )
      end

      it 'returns false' do
        expect(builder).not_to be_valid
      end
    end

    context 'when the "prompt" field is empty for a line,' do
      before do
        row_with_2_choices[:prompt] = ''
      end

      it 'sets an error' do
        builder.valid?

        expect(builder.errors).to contain_exactly(
          "line 2: 'prompt' field cannot be blank"
        )
      end

      it 'returns false' do
        expect(builder).not_to be_valid
      end
    end

    context 'when the "prompt" field for a line contains html,' do
      before do
        row_with_2_choices[:prompt] = '<b>foo</b>'
      end

      it 'sets an error' do
        builder.valid?

        expect(builder.errors).to contain_exactly(
          "line 2: 'prompt' field may not contain html tags, " \
          "current value: '<b>foo</b>'"
        )
      end

      it 'returns false' do
        expect(builder).not_to be_valid
      end
    end

    context 'when the "correct_answer" header is missing,' do
      before do
        row_with_2_choices.delete(:correct_answer)
      end

      it 'sets an error' do
        builder.valid?

        expect(builder.errors).to contain_exactly(
          "required column header 'correct_answer' was not found"
        )
      end

      it 'returns false' do
        expect(builder).not_to be_valid
      end
    end

    context 'when the "correct_answer" field is empty for a line,' do
      before do
        row_with_2_choices[:correct_answer] = ''
      end

      it 'sets an error' do
        builder.valid?

        expect(builder.errors).to contain_exactly(
          "line 2: 'correct_answer' field cannot be blank"
        )
      end

      it 'returns false' do
        expect(builder).not_to be_valid
      end
    end

    context 'when the "correct_answer" field for a line contains html,' do
      before do
        row_with_2_choices[:correct_answer] = '<b>foo</b>'
      end

      it 'sets an error' do
        builder.valid?

        expect(builder.errors).to contain_exactly(
          "line 2: 'correct_answer' field may not contain html tags, " \
          "current value: '<b>foo</b>'"
        )
      end

      it 'returns false' do
        expect(builder).not_to be_valid
      end
    end

    context 'when the "distractor_1" header is missing,' do
      before do
        row_with_2_choices.delete(:distractor_1)
      end

      it 'sets an error' do
        builder.valid?

        expect(builder.errors).to contain_exactly(
          "required column header 'distractor_1' was not found"
        )
      end

      it 'returns false' do
        expect(builder).not_to be_valid
      end
    end

    context 'when the "distractor_1" field is empty for a line,' do
      before do
        row_with_2_choices[:distractor_1] = ''
      end

      it 'sets an error' do
        builder.valid?

        expect(builder.errors).to contain_exactly(
          "line 2: 'distractor_1' field cannot be blank"
        )
      end

      it 'returns false' do
        expect(builder).not_to be_valid
      end
    end

    context 'when the "distractor_1" field for a line contains html,' do
      before do
        row_with_2_choices[:distractor_1] = '<b>foo</b>'
      end

      it 'sets an error' do
        builder.valid?

        expect(builder.errors).to contain_exactly(
          "line 2: 'distractor_1' field may not contain html tags, " \
          "current value: '<b>foo</b>'"
        )
      end

      it 'returns false' do
        expect(builder).not_to be_valid
      end
    end

    context 'when specified number of choices is greater than 2,' do
      let(:choices) { 3 }
      let(:lines) do
        [CSV::Row.new(row_with_3_choices.keys, row_with_3_choices.values)]
      end

      context 'when the "distractor_2" header is missing,' do
        before do
          row_with_3_choices.delete(:distractor_2)
        end

        it 'sets an error' do
          builder.valid?

          expect(builder.errors).to contain_exactly(
            "required column header 'distractor_2' was not found"
          )
        end

        it 'returns false' do
          expect(builder).not_to be_valid
        end
      end

      context 'when the "distractor_2" field is empty for a line,' do
        before do
          row_with_3_choices[:distractor_2] = ''
        end

        it 'sets an error' do
          builder.valid?

          expect(builder.errors).to contain_exactly(
            "line 2: 'distractor_2' field cannot be blank"
          )
        end

        it 'returns false' do
          expect(builder).not_to be_valid
        end
      end

      context 'when the "distractor_2" field for a line contains html,' do
        before do
          row_with_3_choices[:distractor_2] = '<b>foo</b>'
        end

        it 'sets an error' do
          builder.valid?

          expect(builder.errors).to contain_exactly(
            "line 2: 'distractor_2' field may not contain html tags, " \
            "current value: '<b>foo</b>'"
          )
        end

        it 'returns false' do
          expect(builder).not_to be_valid
        end
      end
    end

    context 'when specified number of choices is greater than 3,' do
      let(:choices) { 4 }
      let(:lines) do
        [CSV::Row.new(row_with_4_choices.keys, row_with_4_choices.values)]
      end

      context 'when the "distractor_3" header is missing,' do
        before do
          row_with_4_choices.delete(:distractor_3)
        end

        it 'sets an error' do
          builder.valid?

          expect(builder.errors).to contain_exactly(
            "required column header 'distractor_3' was not found"
          )
        end

        it 'returns false' do
          expect(builder).not_to be_valid
        end
      end

      context 'when the "distractor_3" field is empty for a line,' do
        before do
          row_with_4_choices[:distractor_3] = ''
        end

        it 'sets an error' do
          builder.valid?

          expect(builder.errors).to contain_exactly(
            "line 2: 'distractor_3' field cannot be blank"
          )
        end

        it 'returns false' do
          expect(builder).not_to be_valid
        end
      end

      context 'when the "distractor_3" field for a line contains html,' do
        before do
          row_with_4_choices[:distractor_3] = '<b>foo</b>'
        end

        it 'sets an error' do
          builder.valid?

          expect(builder.errors).to contain_exactly(
            "line 2: 'distractor_3' field may not contain html tags, " \
            "current value: '<b>foo</b>'"
          )
        end

        it 'returns false' do
          expect(builder).not_to be_valid
        end
      end
    end
  end
end
