describe QuestionBanks::OpenEndedBuilder do
  let(:direction_line) { 'my dl' }
  let(:title) { 'my title' }

  let(:exam_reference_class) do
    MaestroActivityEngine::ActivityContent::Reference::Exam
  end

  let(:exam_reference) { instance_double(exam_reference_class) }

  let(:valid_row) do
    { prompt: 'write a long answer' }
  end

  let(:lines) do
    [CSV::Row.new(valid_row.keys, valid_row.values)]
  end

  let(:attrs) do
    {
      exam_reference: exam_reference,
      lines: lines,
      metadata: {
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
      MaestroActivityEngine::ActivityContent::OpenEndedContent
    end
    let(:content) { instance_double(activity_class) }

    before do
      allow(activity_class).to receive(:from_csv_hash).and_return(content)
    end

    it 'calls .from_csv_hash on the OpenEndedContent class, ' \
       'passing in the specified direction_line, exam_reference, and title' do
      builder.content_object

      expect(activity_class).to have_received(:from_csv_hash).with(
        hash_including(
          direction_line: direction_line,
          exam_reference: exam_reference,
          title: title
        )
      )
    end

    it 'specifies an item data entry for each line, with a prompt and a ' \
       '1-indexed number' do
      builder.content_object

      expect(activity_class).to have_received(:from_csv_hash).with(
        hash_including(
          item_data: [
            { number: 1, prompt: 'write a long answer' }
          ]
        )
      )
    end

    it 'handles markdown for bold and italics in the prompt' do
      valid_row[:prompt] = 'normal **bold** normal __italic__'
      expected_prompt = 'normal <b>bold</b> normal <i>italic</i>'

      builder.content_object

      expect(activity_class).to have_received(:from_csv_hash).with(
        hash_including(
          item_data: [
            { number: 1, prompt: expected_prompt }
          ]
        )
      )
    end

    context 'when the prompt contains double plus signs,' do
      context 'when the prompt language is english,' do
        before do
          valid_row[:prompt] = 'english ++foreign1++ english ' \
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
                { number: 1, prompt: expected_prompt }
              ]
            )
          )
        end
      end

      context 'when the prompt language is foreign,' do
        before do
          valid_row[:prompt] = 'foreign ++english1++ foreign ' \
                               '++english2++ foreign'
          attrs[:metadata][:prompt_lang] = 'es'
        end

        it 'replaces double plus signs in the prompt with language span ' \
           'tags specifying the target language' do
          expected_prompt = 'foreign <span lang="en"><i>english1</i></span> ' \
                            'foreign <span lang="en"><i>english2</i></span> ' \
                            'foreign'

          builder.content_object

          expect(activity_class).to have_received(:from_csv_hash).with(
            hash_including(
              item_data: [
                { number: 1, prompt: expected_prompt }
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
        valid_row.delete(:prompt)
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
        valid_row[:prompt] = ''
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
        valid_row[:prompt] = '<b>foo</b>'
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
  end
end
