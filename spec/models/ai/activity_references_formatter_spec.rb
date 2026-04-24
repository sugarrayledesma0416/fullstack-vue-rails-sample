require 'rails_helper'

RSpec.describe AI::ActivityReferencesFormatter do
  let(:activity) { create(:activity_with_program) }
  let(:formatter) { described_class.new(activity) }
  let(:extractor) { instance_double(AI::ActivityExtractor) }

  before do
    allow(AI::ActivityExtractor).to receive(:new).with(activity).and_return(extractor)
  end

  describe '#initialize' do
    it 'sets the activity_or_preview instance variable' do
      formatter = described_class.new(activity)
      expect(formatter.activity_or_preview).to eq(activity)
    end
  end

  describe '#format_as_xml' do
    context 'when activity_or_preview is nil' do
      let(:formatter) { described_class.new(nil) }

      it 'returns nil' do
        expect(formatter.format_as_xml).to be_nil
      end
    end

    context 'when reference_data is empty' do
      before do
        allow(extractor).to receive(:reference_data).and_return({})
      end

      it 'returns nil' do
        expect(formatter.format_as_xml).to be_nil
      end
    end

    context 'when reference_data contains all reference types' do
      let(:reference_data) do
        {
          audio_transcripts: ['Audio transcript text 1', 'Audio transcript text 2'],
          dialogue_segments: [
            { speaker: 'Speaker 1', speech: 'Speech 1' },
            { speaker: 'Speaker 2', speech: 'Speech 2' }
          ],
          email_data: [
            { from: 'sender@example.com', subject: 'Subject 1', body: 'Body 1' },
            { from: 'another@example.com', subject: 'Subject 2', body: 'Body 2' }
          ],
          headings: ['Heading 1', 'Heading 2'],
          id_card_data: [
            { name: 'Name 1', paragraph: 'Paragraph 1' },
            { name: 'Name 2', paragraph: 'Paragraph 2' }
          ],
          image_alt_tags: ['Image alt tag 1', 'Image alt tag 2'],
          internet_keywords: [
            { target: 'target1', base: 'base1' },
            { target: 'target2', base: 'base2' }
          ],
          list_items: [
            { header: 'List 1', body: 'Body 1' },
            { header: 'List 2', body: 'Body 2' }
          ],
          model_texts: ['Model text 1', 'Model text 2'],
          model_v2_texts: [
            { language: 'en', header: 'Header 1', content: 'Content 1' },
            { language: 'es', header: 'Header 2', content: 'Content 2' }
          ],
          panel_groups: [
            { title: 'Panel 1' },
            { title: 'Panel 2' }
          ],
          paragraphs: ['Paragraph 1', 'Paragraph 2'],
          paragraph_v2_texts: ['Paragraph v2 1', 'Paragraph v2 2'],
          social_media_posts: [
            { name: 'Name 1', content: 'Content 1' },
            { name: 'Name 2', content: 'Content 2' }
          ],
          table_xmls: ['<tr><td>Table 1</td></tr>', '<tr><td>Table 2</td></tr>'],
          video_transcripts: ['Video transcript 1', 'Video transcript 2'],
          vocabulary_items: [
            { word: 'Word 1', definition: 'Definition 1' },
            { word: 'Word 2', definition: 'Definition 2' }
          ],
          wordbank_words_list: ['word1, word2', 'word3, word4'],
          character_lists: [
            {
              characters: [
                { name: 'John Doe', image: { id: 1 } },
                { name: 'Jane Smith', image: { id: 2 } }
              ]
            },
            {
              characters: [
                { name: 'Bob Wilson', image: { id: 3 } }
              ]
            }
          ]
        }
      end

      before do
        allow(extractor).to receive(:reference_data).and_return(reference_data)
      end

      it 'returns a properly formatted XML string with all reference types' do
        result = Nokogiri::XML(formatter.format_as_xml)

        expect(result.at_xpath('//references')).to be_present

        # Audio transcripts
        expect(result.at_xpath('//audio_transcripts/transcript[1]').text).to eq('Audio transcript text 1')
        expect(result.at_xpath('//audio_transcripts/transcript[2]').text).to eq('Audio transcript text 2')

        # Dialogue segments
        expect(result.at_xpath('//dialogue_segments/segment[1]/speaker').text).to eq('Speaker 1')
        expect(result.at_xpath('//dialogue_segments/segment[1]/speech').text).to eq('Speech 1')

        # Email data
        expect(result.at_xpath('//emails/email[1]/from').text).to eq('sender@example.com')
        expect(result.at_xpath('//emails/email[1]/subject').text).to eq('Subject 1')
        expect(result.at_xpath('//emails/email[1]/body').text).to eq('Body 1')

        # Headings
        expect(result.at_xpath('//headings/heading[1]').text).to eq('Heading 1')
        expect(result.at_xpath('//headings/heading[2]').text).to eq('Heading 2')

        # ID card data
        expect(result.at_xpath('//id_cards/card[1]/name').text).to eq('Name 1')
        expect(result.at_xpath('//id_cards/card[1]/paragraph').text).to eq('Paragraph 1')

        # Image alt tags
        expect(result.at_xpath('//image_alt_tags/alt_tag[1]').text).to eq('Image alt tag 1')
        expect(result.at_xpath('//image_alt_tags/alt_tag[2]').text).to eq('Image alt tag 2')

        # Internet keywords
        expect(result.at_xpath('//internet_keywords/keyword[1]/target').text).to eq('target1')
        expect(result.at_xpath('//internet_keywords/keyword[1]/base').text).to eq('base1')

        # List items
        expect(result.at_xpath('//lists/list[1]/header').text).to eq('List 1')
        expect(result.at_xpath('//lists/list[1]/body').text).to eq('Body 1')

        # Model texts
        expect(result.at_xpath('//model_texts/model_text[1]').text).to eq('Model text 1')
        expect(result.at_xpath('//model_texts/model_text[2]').text).to eq('Model text 2')

        # Model v2 texts
        expect(result.at_xpath('//model_v2_texts/model_v2_text[1]/language').text).to eq('en')
        expect(result.at_xpath('//model_v2_texts/model_v2_text[1]/header').text).to eq('Header 1')
        expect(result.at_xpath('//model_v2_texts/model_v2_text[1]/content').text).to eq('Content 1')

        # Panel groups
        expect(result.at_xpath('//panel_groups/panel[1]/title').text).to eq('Panel 1')
        expect(result.at_xpath('//panel_groups/panel[2]/title').text).to eq('Panel 2')

        # Paragraphs
        expect(result.at_xpath('//paragraphs/paragraph[1]').text).to eq('Paragraph 1')
        expect(result.at_xpath('//paragraphs/paragraph[2]').text).to eq('Paragraph 2')

        # Paragraph v2 texts
        expect(result.at_xpath('//paragraph_v2_texts/paragraph_v2_text[1]').text).to eq('Paragraph v2 1')
        expect(result.at_xpath('//paragraph_v2_texts/paragraph_v2_text[2]').text).to eq('Paragraph v2 2')

        # Social media posts
        expect(result.at_xpath('//social_media_posts/post[1]/name').text).to eq('Name 1')
        expect(result.at_xpath('//social_media_posts/post[1]/content').text).to eq('Content 1')

        # Tables
        expect(result.at_xpath('//tables/table[1]//tr//td').text).to eq('Table 1')
        expect(result.at_xpath('//tables/table[2]//tr//td').text).to eq('Table 2')

        # Video transcripts
        expect(result.at_xpath('//video_transcripts/transcript[1]').text).to eq('Video transcript 1')
        expect(result.at_xpath('//video_transcripts/transcript[2]').text).to eq('Video transcript 2')

        # Vocabulary items
        expect(result.at_xpath('//vocabulary_items/item[1]/word').text).to eq('Word 1')
        expect(result.at_xpath('//vocabulary_items/item[1]/definition').text).to eq('Definition 1')

        # Wordbank words
        expect(result.at_xpath('//wordbank_words/words[1]').text).to eq('word1, word2')
        expect(result.at_xpath('//wordbank_words/words[2]').text).to eq('word3, word4')

        # Character lists
        expect(result.at_xpath('//character_lists/character_list[1]/characters/character[1]/name').text).to eq('John Doe')
        expect(result.at_xpath('//character_lists/character_list[1]/characters/character[1]/image/@id').text).to eq('1')
        expect(result.at_xpath('//character_lists/character_list[1]/characters/character[2]/name').text).to eq('Jane Smith')
        expect(result.at_xpath('//character_lists/character_list[1]/characters/character[2]/image/@id').text).to eq('2')
        expect(result.at_xpath('//character_lists/character_list[2]/characters/character[1]/name').text).to eq('Bob Wilson')
        expect(result.at_xpath('//character_lists/character_list[2]/characters/character[1]/image/@id').text).to eq('3')
      end
    end

    context 'when reference_data contains only some resources' do
      let(:reference_data) do
        {
          audio_transcripts: ['Audio transcript text'],
          dialogue_segments: [{ speaker: 'Speaker', speech: 'Speech' }],
          model_texts: ['Model text content']
        }
      end

      before do
        allow(extractor).to receive(:reference_data).and_return(reference_data)
      end

      it 'returns a properly formatted XML string with only the available references' do
        result = Nokogiri::XML(formatter.format_as_xml)

        expect(result.at_xpath('//references')).to be_present
        expect(result.at_xpath('//audio_transcripts/transcript').text).to eq('Audio transcript text')
        expect(result.at_xpath('//dialogue_segments/segment/speaker').text).to eq('Speaker')
        expect(result.at_xpath('//dialogue_segments/segment/speech').text).to eq('Speech')
        expect(result.at_xpath('//model_texts/model_text[1]').text).to eq('Model text content')

        # Verify other reference types are not present
        expect(result.at_xpath('//image_alt_tags')).to be_nil
        expect(result.at_xpath('//tables')).to be_nil
        expect(result.at_xpath('//video_transcripts')).to be_nil
        expect(result.at_xpath('//wordbank_words')).to be_nil
        expect(result.at_xpath('//character_lists')).to be_nil
      end
    end

    context 'when reference_data contains complex nested structures' do
      let(:reference_data) do
        {
          dialogue_segments: [
            { speaker: 'Speaker 1', speech: 'Speech with & entities' },
          ],
          email_data: [
            { from: 'sender@example.com', subject: 'Subject with <i>formatting</i>', body: "Body with\nline breaks" }
          ],
          model_v2_texts: [
            { language: 'en', header: 'Header with <em>emphasis</em>', content: 'Content with "quotes"' }
          ]
        }
      end

      before do
        allow(extractor).to receive(:reference_data).and_return(reference_data)
      end

      it 'handles HTML tags and special characters without escaping' do
        result = Nokogiri::XML(formatter.format_as_xml)

        expect(result.at_xpath('//dialogue_segments/segment[1]/speech').text).to eq('Speech with & entities')
        expect(result.at_xpath('//emails/email/subject').text).to eq('Subject with <i>formatting</i>')
        expect(result.at_xpath('//emails/email/body').text).to eq("Body with\nline breaks")
        expect(result.at_xpath('//model_v2_texts/model_v2_text[1]/header').text).to eq('Header with <em>emphasis</em>')
        expect(result.at_xpath('//model_v2_texts/model_v2_text[1]/content').text).to eq('Content with "quotes"')
      end
    end

    context 'when character lists have whitespace in names' do
      let(:reference_data) do
        {
          character_lists: [
            {
              characters: [
                { name: '  John  Doe  ', image: { id: 1 } },
                { name: nil, image: { id: 2 } },
                { name: '', image: { id: 3 } }
              ]
            }
          ]
        }
      end

      before do
        allow(extractor).to receive(:reference_data).and_return(reference_data)
      end

      it 'properly handles whitespace and nil/empty names' do
        result = Nokogiri::XML(formatter.format_as_xml)

        expect(result.at_xpath('//character_lists/character_list[1]/characters/character[1]/name').text).to eq('John Doe')
        expect(result.at_xpath('//character_lists/character_list[1]/characters/character[1]/image/@id').text).to eq('1')
        expect(result.at_xpath('//character_lists/character_list[1]/characters/character[2]/name')).to be_nil
        expect(result.at_xpath('//character_lists/character_list[1]/characters/character[2]/image/@id').text).to eq('2')
        expect(result.at_xpath('//character_lists/character_list[1]/characters/character[3]/name')).to be_nil
        expect(result.at_xpath('//character_lists/character_list[1]/characters/character[3]/image/@id').text).to eq('3')
      end
    end
  end
end