require 'rails_helper'
require 'maestro_activity_engine'

RSpec.describe AI::ActivityExtractor do

  let(:program) { create(:program, language_code: 'en') }
  let(:activity) { create(:activity_with_program) }
  let(:extractor) { described_class.new(activity) }

  describe '#activity_title' do
    it 'returns the activity title with tags stripped and HTML decoded' do
      allow(activity).to receive(:title).and_return('<p>Test Activity</p>')
      expect(extractor.activity_title).to eq('Test Activity')
    end
  end

  describe '#direction_line' do
    let(:content_object) { double('ContentObject') }
    let(:dl) { double('DirectionLine') }

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(content_object).to receive(:dl).and_return(dl)
      allow(dl).to receive(:text).and_return('<p>Test Direction</p>')
    end

    it 'returns the direction line with tags stripped and squished' do
      expect(extractor.direction_line).to eq('Test Direction')
    end

    it 'returns nil when content_object is nil' do
      allow(activity).to receive(:content_object).and_return(nil)
      expect(extractor.direction_line).to be_nil
    end
  end

  describe '#language_code' do
    it 'returns the program language code' do
      allow(activity).to receive(:program).and_return(program)
      expect(extractor.language_code).to eq('en')
    end
  end

  describe '#question_by_label' do
    let(:content_object) { double('ContentObject') }
    let(:items) { [double('Item', label: 'q1'), double('Item', label: 'q2')] }

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(content_object).to receive(:items).and_return(items)
    end

    it 'returns the question with the given label' do
      expect(extractor.question_by_label('q1')).to eq(items.first)
    end

    it 'returns nil when no question with the label exists' do
      expect(extractor.question_by_label('nonexistent')).to be_nil
    end
  end

  describe '#question_sample_answers' do
    let(:question) { double('Question', sample_answer: %w[answer1 answer2]) }

    before do
      allow(extractor).to receive(:question_by_label).with('q1').and_return(question)
    end

    it 'returns the sample answers for the question' do
      expect(extractor.question_sample_answers('q1')).to eq(%w[answer1 answer2])
    end

    it 'returns an empty array when the question is nil' do
      allow(extractor).to receive(:question_by_label).with('nonexistent').and_return(nil)
      expect(extractor.question_sample_answers('nonexistent')).to eq([])
    end
  end

  describe '#question_prompt' do
    let(:prompt) { double('Prompt', text: '<p>Test Prompt</p>') }
    let(:question) { double('Question', prompt:) }

    before do
      allow(extractor).to receive(:question_by_label).with('q1').and_return(question)
    end

    it 'returns the prompt text with tags stripped and squished' do
      expect(extractor.question_prompt('q1')).to eq('Test Prompt')
    end

    it 'returns an empty string when the question is nil' do
      allow(extractor).to receive(:question_by_label).with('nonexistent').and_return(nil)
      expect(extractor.question_prompt('nonexistent')).to eq('')
    end
  end

  describe '#reference_data' do
    let(:content_object) { double('ContentObject') }
    let(:references) { [] }

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(content_object).to receive(:references).and_return(references)
    end

    it 'returns an empty hash when no references are present' do
      expect(extractor.reference_data).to eq({})
    end

    context 'with audio reference' do
      let(:audio_reference) { double('AudioReference', type: 'audio', ai_target: 'both') }
      let(:audio) { double('Audio') }
      let(:media_item) { double('MediaItem', transcript: 'Audio Transcript (/)') }

      before do
        references << audio_reference
        allow(audio_reference).to receive(:audio).and_return(audio)
        allow(audio).to receive(:media_item).and_return(media_item)
      end

      it 'includes audio_transcripts in the reference data' do
        expect(extractor.reference_data[:audio_transcripts]).to eq(['Audio Transcript'])
      end
    end

    context 'with image reference' do
      let(:image_reference) { double('ImageReference', type: 'image', ai_target: 'both') }
      let(:image) { double('Image') }
      let(:media_item) { double('MediaItem', alt_tag: 'Image Alt Tag') }

      before do
        references << image_reference
        allow(image_reference).to receive(:image).and_return(image)
        allow(image).to receive(:media_item).and_return(media_item)
      end

      it 'includes image_alt_tags in the reference data' do
        expect(extractor.reference_data[:image_alt_tags]).to eq(['Image Alt Tag'])
      end
    end

    context 'with model reference' do
      let(:model_reference) { double('ModelReference', type: 'model', ai_target: 'both') }
      let(:body) { double('Body', text: '<p>Model Text</p>') }

      before do
        references << model_reference
        allow(model_reference).to receive(:body).and_return(body)
      end

      it 'includes model_texts in the reference data' do
        expect(extractor.reference_data[:model_texts]).to eq(['Model Text'])
      end
    end

    context 'with table reference' do
      let(:table_reference) { double('TableReference', type: 'table', ai_target: 'both') }
      let(:caption) { double('Caption', content: 'Table Caption') }
      let(:header_row) do
        double('HeaderRow',
               cells: [double('Cell', content: 'Header 1'), double('Cell', content: 'Header 2')])
      end
      let(:body_row) do
        double('BodyRow',
               cells: [double('Cell', content: 'Data 1'), double('Cell', content: 'Data 2')])
      end
      let(:footer_row) do
        double('FooterRow',
               cells: [double('Cell', content: 'Footer 1'), double('Cell', content: 'Footer 2')])
      end

      before do
        references << table_reference
        allow(table_reference).to receive(:caption).and_return(caption)
        allow(table_reference).to receive(:header_rows).and_return([header_row])
        allow(table_reference).to receive(:body_rows).and_return([body_row])
        allow(table_reference).to receive(:footer_rows).and_return([footer_row])
      end

      it 'includes table_xmls in the reference data' do
        table_xmls = extractor.reference_data[:table_xmls]
        expect(table_xmls).to be_an(Array)
        expect(table_xmls.length).to eq(1)

        table_xml = table_xmls.first
        expect(table_xml).to include('<table>')
        expect(table_xml).to include('<caption>Table Caption</caption>')
        expect(table_xml).to include('<thead>')
        expect(table_xml).to include('<th>Header 1</th>')
        expect(table_xml).to include('<th>Header 2</th>')
        expect(table_xml).to include('<tbody>')
        expect(table_xml).to include('<td>Data 1</td>')
        expect(table_xml).to include('<td>Data 2</td>')
        expect(table_xml).to include('<tfoot>')
        expect(table_xml).to include('<td>Footer 1</td>')
        expect(table_xml).to include('<td>Footer 2</td>')
      end
    end

    context 'with video reference' do
      let(:video_reference) { double('VideoReference', type: 'video', ai_target: 'both') }
      let(:video) { double('Video') }
      let(:media_item) { double('MediaItem', transcript: '<p>Video Transcript</p>') }

      before do
        references << video_reference
        allow(video_reference).to receive(:video).and_return(video)
        allow(video).to receive(:media_item).and_return(media_item)
      end

      it 'includes video_transcripts in the reference data' do
        expect(extractor.reference_data[:video_transcripts]).to eq(['Video Transcript'])
      end
    end

    context 'with wordbank reference' do
      let(:wordbank_reference) { double('WordbankReference', type: 'wordbank', ai_target: 'both') }
      let(:words) { %w[word1 word2 word3] }

      before do
        references << wordbank_reference
        allow(wordbank_reference).to receive(:words).and_return(words)
      end

      it 'includes wordbank_words_list in the reference data' do
        expect(extractor.reference_data[:wordbank_words_list]).to eq(["word1, word2, word3"])
      end
    end

    context 'with character list references' do
      let(:character_list_reference1) { double('CharacterListReference', type: 'character_list', ai_target: 'both') }
      let(:character_list_reference2) { double('CharacterListReference', type: 'character_list', ai_target: 'both') }
      let(:character1) { double('Character', name: 'John Doe', image: double('Image', id: 1)) }
      let(:character2) { double('Character', name: 'Jane Smith', image: double('Image', id: 2)) }
      let(:character3) { double('Character', name: 'Bob Wilson', image: double('Image', id: 3)) }

      before do
        references << character_list_reference1
        references << character_list_reference2

        allow(character_list_reference1).to receive(:characters).and_return([character1, character2])
        allow(character_list_reference2).to receive(:characters).and_return([character3])
      end

      it 'includes character_lists in the reference data' do
        expected_data = [
          {
            characters: [
              {
                name: 'John Doe'
              },
              {
                name: 'Jane Smith'
              }
            ]
          },
          {
            characters: [
              {
                name: 'Bob Wilson'
              }
            ]
          }
        ]

        expect(extractor.reference_data[:character_lists]).to eq(expected_data)
      end

      it 'handles empty character lists' do
        allow(character_list_reference1).to receive(:characters).and_return([])
        allow(character_list_reference2).to receive(:characters).and_return(nil)

        expected_data = [
          {
            characters: []
          },
          {
            characters: []
          }
        ]

        expect(extractor.reference_data[:character_lists]).to eq(expected_data)
      end
    end
  end

  describe '#references' do
    let(:content_object) { double('ContentObject') }
    let(:reference_1) { instance_double('Reference', ai_target: 'both') }
    let(:reference_2) { instance_double('Reference', ai_target: 'ai_only') }
    let(:reference_3) { instance_double('Reference', ai_target: 'student_only') }
    let(:reference_4) { instance_double('Reference', ai_target: nil) } # should default to 'both'
    let(:references) { [reference_1, reference_2, reference_3, reference_4] }

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(content_object).to receive(:references).and_return(references)
    end

    it 'filters out references with ai_target === "student_only"' do
      expect(extractor.send(:references)).to contain_exactly(reference_1, reference_2, reference_4)
    end

    it 'memoizes the filtered references' do
      first_call = extractor.send(:references)
      second_call = extractor.send(:references)
      expect(first_call).to equal(second_call)
    end
  end

  describe 'reference getters' do
    let(:content_object) { double('ContentObject') }
    let(:audio_reference) { instance_double('Reference', type: 'audio', ai_target: 'both') }
    let(:image_reference) { instance_double('Reference', type: 'image', ai_target: 'both') }
    let(:model_reference) { instance_double('Reference', type: 'model', ai_target: 'both') }
    let(:table_reference) { instance_double('Reference', type: 'table', ai_target: 'both') }
    let(:video_reference) { instance_double('Reference', type: 'video', ai_target: 'both') }
    let(:wordbank_reference) { instance_double('Reference', type: 'wordbank', ai_target: 'both') }
    let(:student_only_reference) do
      instance_double('Reference', type: 'audio', ai_target: 'student_only')
    end

    let(:references) do
      [
        audio_reference,
        image_reference,
        model_reference,
        table_reference,
        video_reference,
        wordbank_reference,
        student_only_reference
      ]
    end

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(content_object).to receive(:references).and_return(references)
    end

    it 'audio_references does not include student_only references' do
      expect(extractor.send(:audio_references)).to eq([audio_reference])
    end

    it 'image_references does not include student_only references' do
      expect(extractor.send(:image_references)).to eq([image_reference])
    end

    it 'model_references does not include student_only references' do
      expect(extractor.send(:model_references)).to eq([model_reference])
    end

    it 'table_reference does not include student_only references' do
      expect(extractor.send(:table_reference)).to eq(table_reference)
    end

    it 'video_references does not include student_only references' do
      expect(extractor.send(:video_references)).to eq([video_reference])
    end

    it 'wordbank_references does not include student_only references' do
      expect(extractor.send(:wordbank_references)).to eq([wordbank_reference])
    end
  end
end
