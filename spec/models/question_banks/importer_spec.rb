describe QuestionBanks::Importer do
  describe '#import' do
    let(:language_code) { 'es' }
    let(:program) { create(:program, language_code: language_code) }
    let(:concept) { create(:concept, program: program) }
    let(:topic) { create(:question_bank_topic) }

    let(:question_bank) { QuestionBank.new(question_bank_topic: topic) }

    let(:valid_langs) do
      MaestroActivityEngine::Languages.valid_activity_codes.join(', ')
    end

    let(:exam_content_class) do
      MaestroActivityEngine::ActivityContent::ExamContent
    end

    let(:json) do
      File.read(
        File.join('spec', 'fixtures', 'json', 'open_ended_question_bank.json')
      )
    end

    let(:exam_content) do
      instance_double(exam_content_class, :activities= => nil, to_json: json)
    end

    let(:exam_reference_class) do
      MaestroActivityEngine::ActivityContent::Reference::Exam
    end

    let(:exam_reference) { instance_double(exam_reference_class) }

    let(:builder_class) { QuestionBanks::MultipleChoiceBuilder }

    let(:content_object) do
      instance_double(
        MaestroActivityEngine::ActivityContent::MultipleChoiceContent
      )
    end

    let(:builder) do
      instance_double(
        builder_class,
        valid?: true,
        errors: [],
        content_object: content_object
      )
    end

    before do
      create(
        :question_bank_topics_concept,
        concept: concept,
        question_bank_topic: topic
      )

      allow(exam_content_class).to receive(:from_csv_hash)
        .and_return(exam_content)
      allow(exam_reference_class).to receive(:from_csv_hash)
        .and_return(exam_reference)
      allow(builder_class).to receive(:new).and_return(builder)
    end

    it 'sets errors if any required metadata headers are missing' do
      lines = [',,,,,,,,', ',,,,,,,,']
      importer = described_class.new(lines: lines, question_bank: question_bank)
      importer.import

      expect(question_bank.errors.full_messages).to contain_exactly(
        "required column header 'bank_name' was not found",
        "required column header 'direction_line' was not found",
        "required column header 'dl_lang' was not found",
        "required column header 'item_type' was not found",
        "required column header 'prompt_lang' was not found"
      )
    end

    it 'sets errors if any required metadata fields are blank' do
      lines = ['bank_name,direction_line,item_type,dl_lang,prompt_lang', ',,,,']

      importer = described_class.new(lines: lines, question_bank: question_bank)
      importer.import

      expect(question_bank.errors.full_messages).to contain_exactly(
        "metadata field 'bank_name' cannot be blank",
        "metadata field 'direction_line' cannot be blank",
        "metadata field 'dl_lang' cannot be blank",
        "metadata field 'item_type' cannot be blank",
        "metadata field 'prompt_lang' cannot be blank"
      )
    end

    it 'sets an error if the item_type metadata value is not one of the ' \
       'valid item types' do
      lines = [
        'bank_name,direction_line,dl_lang,prompt_lang,item_type',
        'foo,bar,en,es,bad_type'
      ]

      importer = described_class.new(lines: lines, question_bank: question_bank)
      importer.import

      valid_types = described_class::VALID_ITEM_TYPES.join(', ')
      expect(question_bank.errors.full_messages).to contain_exactly(
        "value 'bad_type' for metadata field 'item_type' " \
        "is not one of the acceptable types: #{valid_types}"
      )
    end

    it 'sets an error if the dl_lang metadata value is not one of the ' \
       'valid languages' do
      lines = [
        'bank_name,direction_line,dl_lang,prompt_lang,item_type',
        'foo,bar,badlang,es,bad_type'
      ]

      importer = described_class.new(lines: lines, question_bank: question_bank)
      importer.import

      expect(question_bank.errors.full_messages).to contain_exactly(
        "value 'badlang' for metadata field 'dl_lang' " \
        "is not one of the valid language codes: #{valid_langs}"
      )
    end

    it 'sets an error if the prompt_lang metadata value is not one of the ' \
       'valid languages' do
      lines = [
        'bank_name,direction_line,dl_lang,prompt_lang,item_type',
        'foo,bar,en,badlang,mc_3'
      ]

      importer = described_class.new(lines: lines, question_bank: question_bank)
      importer.import

      expect(question_bank.errors.full_messages).to contain_exactly(
        "value 'badlang' for metadata field 'prompt_lang' " \
        "is not one of the valid language codes: #{valid_langs}"
      )
    end

    it 'sets errors if the title or direction line contain html tags' do
      lines = [
        'bank_name,direction_line,dl_lang,prompt_lang,item_type',
        '<b>foo</b>,bar<br />baz,en,es,mc_3'
      ]

      importer = described_class.new(lines: lines, question_bank: question_bank)
      importer.import

      expect(question_bank.errors.full_messages).to contain_exactly(
        "metadata field 'bank_name' may not contain html tags, " \
        "current value: '<b>foo</b>'",
        "metadata field 'direction_line' may not contain html tags, " \
        "current value: 'bar<br />baz'"
      )
    end

    context 'with any valid item_type,' do
      it 'calls the from_csv_hash method on the MaestroActivityEngine ' \
         'ExamContent class, passing in the language_code of the program ' \
         'associated with the specified content, and the bank_name and ' \
         'direction_line from the metadata.' do
        lines = [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang',
          'my bank name,my dl,mc_3,en,es,es'
        ]

        importer = described_class.new(lines: lines, question_bank: question_bank)
        importer.import

        expect(exam_content_class).to have_received(:from_csv_hash).with(
          direction_line: 'my dl',
          language: language_code,
          title: 'my bank name'
        )
      end

      it 'wraps text in the direction line delimited by double asterisks ' \
         'with bold tags' do
        lines = [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang',
          'my bank name,english **bold me** english **and me** english,mc_3,en,es,es'
        ]
        importer = described_class.new(lines: lines, question_bank: question_bank)
        importer.import

        expected_dl = 'english <b>bold me</b> english <b>and me</b> english'

        expect(exam_content_class).to have_received(:from_csv_hash).with(
          direction_line: expected_dl,
          language: language_code,
          title: 'my bank name'
        )
      end

      it 'wraps text in the direction line delimited by double underscores ' \
         'with italic tags' do
        lines = [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang',
          'my bank name,english __ital me__ english __and me__ english,mc_3,en,es,es'
        ]
        importer = described_class.new(lines: lines, question_bank: question_bank)
        importer.import

        expected_dl = 'english <i>ital me</i> english <i>and me</i> english'

        expect(exam_content_class).to have_received(:from_csv_hash).with(
          direction_line: expected_dl,
          language: language_code,
          title: 'my bank name'
        )
      end

      it 'handles bold, italic, and nested bold and italic in the ' \
         'direction line' do
        lines = [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang',
          'my bank name,normal **bold __and italic__ bold** normal ' \
          '**just bold**normalnospace__just italic__ normal ' \
          '__italic **and bold** italic__ normal,mc_3,en,es,es'
        ]
        importer = described_class.new(lines: lines, question_bank: question_bank)
        importer.import

        expected_dl = 'normal <b>bold <i>and italic</i> bold</b> normal ' \
                      '<b>just bold</b>normalnospace<i>just italic</i> normal ' \
                      '<i>italic <b>and bold</b> italic</i> normal'

        expect(exam_content_class).to have_received(:from_csv_hash).with(
          direction_line: expected_dl,
          language: language_code,
          title: 'my bank name'
        )
      end

      context 'when the direction line language is english,' do
        let(:lines) do
          [
            'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang',
            'my bank name,english ++foreign1++ english ++foreign2++ english,' \
            'mc_3,en,es,es'
          ]
        end

        it 'wraps text in the direction line delimited by double plus signs ' \
           'with span tags specifying the target language' do
          importer = described_class.new(lines: lines, question_bank: question_bank)
          importer.import

          expected_dl = 'english <span lang="es"><b>foreign1</b></span> english ' \
                        '<span lang="es"><b>foreign2</b></span> english'

          expect(exam_content_class).to have_received(:from_csv_hash).with(
            direction_line: expected_dl,
            language: language_code,
            title: 'my bank name'
          )
        end
      end

      context 'when the direction line language is foreign,' do
        let(:lines) do
          [
            'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang',
            'my bank name,foreign ++english1++ foreign ++english2++ foreign,' \
            'mc_3,es,es,es'
          ]
        end

        it 'wraps text in the direction line delimited by double plus signs ' \
           'with span tags specifying english language' do
          importer = described_class.new(lines: lines, question_bank: question_bank)
          importer.import

          expected_dl = 'foreign <span lang="en"><i>english1</i></span> foreign ' \
                        '<span lang="en"><i>english2</i></span> foreign'

          expect(exam_content_class).to have_received(:from_csv_hash).with(
            direction_line: expected_dl,
            language: language_code,
            title: 'my bank name'
          )
        end
      end

      it 'handles text in the direction line where multiple words are ' \
         'delimited with double plus signs' do
        lines = [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang',
          'my bank name,english ++multiple words++ english,mc_3,en,es,es'
        ]

        importer = described_class.new(lines: lines, question_bank: question_bank)
        importer.import

        expected_dl = 'english <span lang="es"><b>multiple words</b></span> ' \
                      'english'

        expect(exam_content_class).to have_received(:from_csv_hash).with(
          direction_line: expected_dl,
          language: language_code,
          title: 'my bank name'
        )
      end

      it 'calls the from_csv_hash method on the MaestroActivityEngine ' \
         'Exam Reference class, passing in a rank of 1, and the bank_name ' \
         'and direction_line from the metadata' do
        lines = [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang',
          'my bank name,my ++dl++,mc_3,en,es,es'
        ]

        importer = described_class.new(lines: lines, question_bank: question_bank)
        importer.import

        expect(exam_reference_class).to have_received(:from_csv_hash).with(
          body: 'my <span lang="es"><b>dl</b></span>',
          header: 'my bank name',
          rank: 1
        )
      end

      context 'when validation is successful,' do
        let(:lines) do
          [
            'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang',
            'my bank name,my dl,mc_3,en,es,es'
          ]
        end

        let(:importer) do
          described_class.new(lines: lines, question_bank: question_bank)
        end

        before do
          allow(builder).to receive(:valid?).and_return(true)
        end

        it 'sets the content_json of the question bank to the exam ' \
           'content object serialized to json' do
          importer.import

          expect(question_bank.content_json).to eq(json)
        end

        it 'strips escaped newlines from the serialized content object json' do
          allow(question_bank).to receive(:save)

          allow(exam_content).to receive(:to_json).and_return(
            '"dl":{"node_text":"english <span lang=\"es\">' \
            '\n  <b>foreign1</b>\n</span> english <span ' \
            'lang=\"es\">\n  <b>foreign2</b>\n</span> english"}'
          )

          importer.import

          expect(question_bank.content_json).to eq(
            '"dl":{"node_text":"english <span lang=\"es\">' \
            '<b>foreign1</b></span> english <span ' \
            'lang=\"es\"><b>foreign2</b></span> english"}'
          )
        end

        it 'sets the title of the question bank to the bank name ' \
           'from the meta data' do
          importer.import

          expect(question_bank.title).to eq('my bank name')
        end

        it 'saves the question bank' do
          importer.import

          expect(question_bank).to be_persisted
        end

        it 'sets the uploaded_csv attribute of the question bank ' \
           'to the raw_csv argument if it was specified' do
          raw_csv = 'blah,blah'
          importer = described_class.new(
            lines: lines,
            question_bank: question_bank,
            raw_csv: raw_csv
          )

          importer.import

          expect(question_bank.uploaded_csv).to eq(raw_csv)
        end

        it 'sets the changed_by_id attribute of the question bank to the ' \
           'id of the user argument if it was specified' do
          user = create(:user)

          importer = described_class.new(
            lines: lines,
            question_bank: question_bank,
            user: user
          )

          importer.import

          expect(question_bank.changed_by_id).to eq(user.id)
        end

        it 'sets the upload_filename attribute of the question bank to the ' \
           'filename argument if it was specified' do
          filename = 'some_file.csv'

          importer = described_class.new(
            filename: filename,
            lines: lines,
            question_bank: question_bank
          )

          importer.import

          expect(question_bank.upload_filename).to eq(filename)
        end
      end
    end

    context 'when item_type is binary_mc,' do
      let(:builder_class) { QuestionBanks::MultipleChoiceBinaryBuilder }

      let(:content_object) do
        instance_double(
          MaestroActivityEngine::ActivityContent::MultipleChoiceTrueFalseContent
        )
      end

      let(:csv_lines) do
        [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,option_1,option_2,prompt,' \
          'correct_answer',
          'my bank name,my ++dl++,binary_mc,en,es,a,b,my prompt,a'
        ]
      end

      let(:question_line_hash) do
        # order of keys must match column order of csv file
        {
          bank_name: 'my bank name',
          direction_line: 'my ++dl++',
          item_type: 'binary_mc',
          dl_lang: 'en',
          prompt_lang: 'es',
          option_1: 'a',
          option_2: 'b',
          prompt: 'my prompt',
          correct_answer: 'a'
        }
      end

      let(:importer) do
        described_class.new(lines: csv_lines, question_bank: question_bank)
      end

      it 'sets errors if the required option headers are missing' do
        csv_lines[0] = 'bank_name,direction_line,item_type,dl_lang,' \
                       'prompt_lang,,,prompt,correct_answer'

        importer = described_class.new(lines: csv_lines, question_bank: question_bank)
        importer.import

        expect(question_bank.errors.full_messages).to contain_exactly(
          "required column header 'option_1' was not found",
          "required column header 'option_2' was not found"
        )
      end

      it 'sets errors if any required metadata option fields are blank' do
        csv_lines[1] = 'my bank name,my dl,binary_mc,en,es,,,my prompt,a'

        importer = described_class.new(lines: csv_lines, question_bank: question_bank)
        importer.import

        expect(question_bank.errors.full_messages).to contain_exactly(
          "metadata field 'option_1' cannot be blank",
          "metadata field 'option_2' cannot be blank"
        )
      end

      it 'instantiates a new MultipleChoiceBinaryBuilder, specifiying the ' \
         'the direction_line, title, and options from the ' \
         'metadata, the instantiated exam_reference, and an Array of CSV ' \
         'lines parsed into hashes' do
        importer.import

        expect(builder_class).to have_received(:new).with(
          metadata: {
            choice_lang: nil,
            direction_line: 'my <span lang="es"><b>dl</b></span>',
            dl_lang: 'en',
            language_code: 'es',
            prompt_lang: 'es',
            title: 'my bank name'
          },
          exam_reference: exam_reference,
          lines: [
            CSV::Row.new(question_line_hash.keys, question_line_hash.values)
          ],
          options: %w[a b]
        )
      end

      it 'calls valid? on the MultipleChoiceBinaryBuilder instance' do
        importer.import

        expect(builder).to have_received(:valid?)
      end

      context 'when validation fails,' do
        let(:errors) { %w[error1 error2] }

        before do
          allow(builder).to receive(:valid?).and_return(false)
          allow(builder).to receive(:errors).and_return(errors)
          importer.import
        end

        it 'adds each validation error to the question_bank instance' do
          expect(question_bank.errors.full_messages).to contain_exactly(
            'error1', 'error2'
          )
        end

        it 'does not set the activities of the exam content object' do
          expect(exam_content).not_to have_received(:activities=)
        end
      end

      context 'when validation is successful,' do
        before do
          allow(builder).to receive(:valid?).and_return(true)
          importer.import
        end

        it 'calls .content_object on the builder instance' do
          expect(builder).to have_received(:content_object)
        end

        it 'sets the activities of the exam content object to an array ' \
           'containing the result of the .content_object call' do
          expect(exam_content).to have_received(:activities=)
            .with([content_object])
        end
      end
    end

    context 'when item_type is mc_3,' do
      let(:csv_lines) do
        [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang,' \
          'prompt,correct_answer,distractor_1,distractor_2',
          'my bank name,my ++dl++,mc_3,en,es,es,my prompt,a,b,c'
        ]
      end

      let(:question_line_hash) do
        # order of keys must match column order of csv file
        {
          bank_name: 'my bank name',
          direction_line: 'my ++dl++',
          item_type: 'mc_3',
          dl_lang: 'en',
          prompt_lang: 'es',
          choice_lang: 'es',
          prompt: 'my prompt',
          correct_answer: 'a',
          distractor_1: 'b',
          distractor_2: 'c'
        }
      end

      let(:importer) do
        described_class.new(lines: csv_lines, question_bank: question_bank)
      end

      it 'instantiates a new MultipleChoiceBuilder, specifiying "3" for ' \
         'the number of choices, the direction_line and title from the ' \
         'metadata, the instantiated exam_reference, and an Array of CSV ' \
         'lines parsed into hashes' do
        importer.import

        expect(builder_class).to have_received(:new).with(
          choices: 3,
          metadata: {
            choice_lang: 'es',
            direction_line: 'my <span lang="es"><b>dl</b></span>',
            dl_lang: 'en',
            language_code: 'es',
            prompt_lang: 'es',
            title: 'my bank name'
          },
          exam_reference: exam_reference,
          lines: [
            CSV::Row.new(question_line_hash.keys, question_line_hash.values)
          ]
        )
      end

      it 'calls valid? on the MultipleChoiceBuilder instance' do
        importer.import

        expect(builder).to have_received(:valid?)
      end

      it 'sets errors if the required choice_lang header is missing' do
        csv_lines[0] = 'bank_name,direction_line,item_type,dl_lang,prompt_lang,,' \
                       'prompt,correct_answer,distractor_1,distractor_2'

        importer = described_class.new(lines: csv_lines, question_bank: question_bank)
        importer.import

        expect(question_bank.errors.full_messages).to contain_exactly(
          "required column header 'choice_lang' was not found"
        )
      end

      it 'sets errors if the required metadata choice_lang field is blank' do
        csv_lines[1] = 'my bank name,my ++dl++,mc_3,en,es,,my prompt,a,b,c'

        importer = described_class.new(lines: csv_lines, question_bank: question_bank)
        importer.import

        expect(question_bank.errors.full_messages).to contain_exactly(
          "metadata field 'choice_lang' cannot be blank"
        )
      end

      it 'sets an error if the choice_lang metadata value is not one of the ' \
         'valid languages' do
        lines = [
          'bank_name,direction_line,dl_lang,prompt_lang,item_type,choice_lang',
          'foo,bar,en,es,mc_3,badlang'
        ]

        importer = described_class.new(lines: lines, question_bank: question_bank)
        importer.import

        expect(question_bank.errors.full_messages).to contain_exactly(
          "value 'badlang' for metadata field 'choice_lang' " \
          "is not one of the valid language codes: #{valid_langs}"
        )
      end

      context 'when validation fails,' do
        let(:errors) { %w[error1 error2] }

        before do
          allow(builder).to receive(:valid?).and_return(false)
          allow(builder).to receive(:errors).and_return(errors)
          importer.import
        end

        it 'adds each validation error to the question_bank instance' do
          expect(question_bank.errors.full_messages).to contain_exactly(
            'error1', 'error2'
          )
        end

        it 'does not set the activities of the exam content object' do
          expect(exam_content).not_to have_received(:activities=)
        end
      end

      context 'when validation is successful,' do
        before do
          allow(builder).to receive(:valid?).and_return(true)
          importer.import
        end

        it 'calls .content_object on the builder instance' do
          expect(builder).to have_received(:content_object)
        end

        it 'sets the activities of the exam content object to an array ' \
           'containing the result of the .content_object call' do
          expect(exam_content).to have_received(:activities=)
            .with([content_object])
        end
      end
    end

    context 'when item_type is fib,' do
      let(:builder_class) { QuestionBanks::FillInTheBlanksBuilder }

      let(:content_object) do
        instance_double(
          MaestroActivityEngine::ActivityContent::FillInTheBlanksContent
        )
      end

      let(:csv_lines) do
        [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,prompt',
          'my bank name,my ++dl++,fib,en,es,my prompt'
        ]
      end

      let(:question_line_hash) do
        # order of keys must match column order of csv file
        {
          bank_name: 'my bank name',
          direction_line: 'my ++dl++',
          item_type: 'fib',
          dl_lang: 'en',
          prompt_lang: 'es',
          prompt: 'my prompt'
        }
      end

      let(:importer) do
        described_class.new(lines: csv_lines, question_bank: question_bank)
      end

      it 'instantiates a new FillInTheBlanksBuilder, specifiying the ' \
         'the direction_line and title from the metadata, the ' \
         'instantiated exam_reference, and an Array of CSV ' \
         'lines parsed into hashes' do
        importer.import

        expect(builder_class).to have_received(:new).with(
          metadata: {
            choice_lang: nil,
            direction_line: 'my <span lang="es"><b>dl</b></span>',
            dl_lang: 'en',
            language_code: 'es',
            prompt_lang: 'es',
            title: 'my bank name'
          },
          exam_reference: exam_reference,
          lines: [
            CSV::Row.new(question_line_hash.keys, question_line_hash.values)
          ]
        )
      end

      it 'calls valid? on the FillInTheBlanksBuilder instance' do
        importer.import

        expect(builder).to have_received(:valid?)
      end

      context 'when validation fails,' do
        let(:errors) { %w[error1 error2] }

        before do
          allow(builder).to receive(:valid?).and_return(false)
          allow(builder).to receive(:errors).and_return(errors)
          importer.import
        end

        it 'adds each validation error to the question_bank instance' do
          expect(question_bank.errors.full_messages).to contain_exactly(
            'error1', 'error2'
          )
        end

        it 'does not set the activities of the exam content object' do
          expect(exam_content).not_to have_received(:activities=)
        end
      end

      context 'when validation is successful,' do
        before do
          allow(builder).to receive(:valid?).and_return(true)
          importer.import
        end

        it 'calls .content_object on the builder instance' do
          expect(builder).to have_received(:content_object)
        end

        it 'sets the activities of the exam content object to an array ' \
           'containing the result of the .content_object call' do
          expect(exam_content).to have_received(:activities=)
            .with([content_object])
        end
      end
    end

    context 'when item_type is open_ended,' do
      let(:builder_class) { QuestionBanks::OpenEndedBuilder }

      let(:content_object) do
        instance_double(
          MaestroActivityEngine::ActivityContent::OpenEndedContent
        )
      end

      let(:csv_lines) do
        [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,prompt',
          'my bank name,my ++dl++,open_ended,en,es,my prompt'
        ]
      end

      let(:question_line_hash) do
        # order of keys must match column order of csv file
        {
          bank_name: 'my bank name',
          direction_line: 'my ++dl++',
          item_type: 'open_ended',
          dl_lang: 'en',
          prompt_lang: 'es',
          prompt: 'my prompt'
        }
      end

      let(:importer) do
        described_class.new(lines: csv_lines, question_bank: question_bank)
      end

      it 'instantiates a new OpenEndedBuilder, specifiying the ' \
         'the direction_line and title from the metadata, the ' \
         'instantiated exam_reference, and an Array of CSV ' \
         'lines parsed into hashes' do
        importer.import

        expect(builder_class).to have_received(:new).with(
          metadata: {
            choice_lang: nil,
            direction_line: 'my <span lang="es"><b>dl</b></span>',
            dl_lang: 'en',
            language_code: 'es',
            prompt_lang: 'es',
            title: 'my bank name'
          },
          exam_reference: exam_reference,
          lines: [
            CSV::Row.new(question_line_hash.keys, question_line_hash.values)
          ]
        )
      end

      it 'calls valid? on the OpenEndedBuilder instance' do
        importer.import

        expect(builder).to have_received(:valid?)
      end

      context 'when validation fails,' do
        let(:errors) { %w[error1 error2] }

        before do
          allow(builder).to receive(:valid?).and_return(false)
          allow(builder).to receive(:errors).and_return(errors)
          importer.import
        end

        it 'adds each validation error to the question_bank instance' do
          expect(question_bank.errors.full_messages).to contain_exactly(
            'error1', 'error2'
          )
        end

        it 'does not set the activities of the exam content object' do
          expect(exam_content).not_to have_received(:activities=)
        end
      end

      context 'when validation is successful,' do
        before do
          allow(builder).to receive(:valid?).and_return(true)
          importer.import
        end

        it 'calls .content_object on the builder instance' do
          expect(builder).to have_received(:content_object)
        end

        it 'sets the activities of the exam content object to an array ' \
           'containing the result of the .content_object call' do
          expect(exam_content).to have_received(:activities=)
            .with([content_object])
        end
      end
    end

    context 'when item_type is dd_3,' do
      let(:builder_class) { QuestionBanks::DropDownBuilder }

      let(:content_object) do
        instance_double(
          MaestroActivityEngine::ActivityContent::DropDownContent
        )
      end

      let(:csv_lines) do
        [
          'bank_name,direction_line,item_type,dl_lang,prompt_lang,choice_lang,' \
          'prompt,correct_answer,distractor_1,distractor_2',
          'my bank name,my ++dl++,dd_3,en,es,es,my prompt @@menu@@,a,b,c'
        ]
      end

      let(:question_line_hash) do
        # order of keys must match column order of csv file
        {
          bank_name: 'my bank name',
          direction_line: 'my ++dl++',
          item_type: 'dd_3',
          dl_lang: 'en',
          prompt_lang: 'es',
          choice_lang: 'es',
          prompt: 'my prompt @@menu@@',
          correct_answer: 'a',
          distractor_1: 'b',
          distractor_2: 'c'
        }
      end

      let(:importer) do
        described_class.new(lines: csv_lines, question_bank: question_bank)
      end

      it 'instantiates a new DropDownBuilder, specifiying "3" for ' \
         'the number of choices, the direction_line and title from the ' \
         'metadata, the instantiated exam_reference, and an Array of CSV ' \
         'lines parsed into hashes' do
        importer.import

        expect(builder_class).to have_received(:new).with(
          choices: 3,
          metadata: {
            choice_lang: 'es',
            direction_line: 'my <span lang="es"><b>dl</b></span>',
            dl_lang: 'en',
            language_code: 'es',
            prompt_lang: 'es',
            title: 'my bank name'
          },
          exam_reference: exam_reference,
          lines: [
            CSV::Row.new(question_line_hash.keys, question_line_hash.values)
          ]
        )
      end

      it 'calls valid? on the DropDownBuilder instance' do
        importer.import

        expect(builder).to have_received(:valid?)
      end

      it 'sets errors if the required choice_lang header is missing' do
        csv_lines[0] = 'bank_name,direction_line,item_type,dl_lang,prompt_lang,,' \
                       'prompt,correct_answer,distractor_1,distractor_2'

        importer = described_class.new(lines: csv_lines, question_bank: question_bank)
        importer.import

        expect(question_bank.errors.full_messages).to contain_exactly(
          "required column header 'choice_lang' was not found"
        )
      end

      it 'sets errors if the required metadata choice_lang field is blank' do
        csv_lines[1] = 'my bank name,my ++dl++,mc_3,en,es,,my prompt,a,b,c'

        importer = described_class.new(lines: csv_lines, question_bank: question_bank)
        importer.import

        expect(question_bank.errors.full_messages).to contain_exactly(
          "metadata field 'choice_lang' cannot be blank"
        )
      end

      it 'sets an error if the choice_lang metadata value is not one of the ' \
         'valid languages' do
        lines = [
          'bank_name,direction_line,dl_lang,prompt_lang,item_type,choice_lang',
          'foo,bar,en,es,mc_3,badlang'
        ]

        importer = described_class.new(lines: lines, question_bank: question_bank)
        importer.import

        expect(question_bank.errors.full_messages).to contain_exactly(
          "value 'badlang' for metadata field 'choice_lang' " \
          "is not one of the valid language codes: #{valid_langs}"
        )
      end

      context 'when validation fails,' do
        let(:errors) { %w[error1 error2] }

        before do
          allow(builder).to receive(:valid?).and_return(false)
          allow(builder).to receive(:errors).and_return(errors)
          importer.import
        end

        it 'adds each validation error to the question_bank instance' do
          expect(question_bank.errors.full_messages).to contain_exactly(
            'error1', 'error2'
          )
        end

        it 'does not set the activities of the exam content object' do
          expect(exam_content).not_to have_received(:activities=)
        end
      end

      context 'when validation is successful,' do
        before do
          allow(builder).to receive(:valid?).and_return(true)
          importer.import
        end

        it 'calls .content_object on the builder instance' do
          expect(builder).to have_received(:content_object)
        end

        it 'sets the activities of the exam content object to an array ' \
           'containing the result of the .content_object call' do
          expect(exam_content).to have_received(:activities=)
            .with([content_object])
        end
      end
    end
  end
end
