#  encoding: utf-8

describe MediaItemPublishProcessor do
  let(:params) do
    {
      'alt_tag' => '',
      'asset_path' => '/some_path/',
      'cdn' => true,
      'filename' => 'some_file',
      'height' => '10',
      'id' => '1',
      'media_type' => 'audio',
      'long_description' => '',
      'revision_id' => '123',
      'size' => '10',
      'transcript' => '',
      'width' => '10'
    }
  end

  it 'includes BasePublishProcessor' do
    expect(MediaItemPublishProcessor.new(params)).to be_a BasePublishProcessor
  end

  it 'adds an error when cdn param is set to false and there is no value set for payload_tempfile_path' do
    params.merge!({ 'cdn' => false, 'payload_tempfile_path' => ''  })
    new_processor = MediaItemPublishProcessor.new(params)
    new_processor.process_request
    expect(new_processor.errors).to include 'Payload tempfile path is required'
  end

  it 'adds an error when cdn param is set to false and there is no value set for payload_tempfile_path' do
    params.merge!({ 'media_type' => 'vocab_list', 'program_id' => ''  })
    new_processor = MediaItemPublishProcessor.new(params)
    new_processor.process_request
    expect(new_processor.errors).to include 'Program id for vocab lists is required'
  end

  describe '#process_request' do
    let(:media_item) { build(:media_item_image) }
    let(:retriever)  { double('MediaFileRetriever', :result => 'some_file', :error => nil) }

    before do
      allow(MediaItem).to receive(:find_by_id).and_return(media_item)
      allow(MediaItemPublishProcessor::MediaFileRetriever).to receive(:new).and_return(retriever)
      allow(media_item).to receive(:update)
      allow(media_item).to receive(:payload=).and_return(true)
      allow(retriever).to receive(:retrieve).and_return(retriever)
      allow(retriever).to receive(:result).and_return('file content')
    end

    context 'when media item is not in cdn' do
      before do
        params.merge!({ 'cdn' => false, 'payload_tempfile_path' => 'some_path' })
      end

      it 'instantiates a MediaFileRetriever' do
        expect(MediaItemPublishProcessor::MediaFileRetriever).to receive(:new).with(params['payload_tempfile_path'], '10').and_return(retriever)
        new_processor = MediaItemPublishProcessor.new(params)
        new_processor.process_request
      end

      it "retrieves the media file" do
        expect(retriever).to receive(:retrieve)
        new_processor = MediaItemPublishProcessor.new(params)
        new_processor.process_request
      end

      context 'when media item is vocab_list' do
        let(:program) { build_stubbed(:program) }
        let(:replacer)  { double('DefaultVocabWordsReplacer', replace: nil) }

        before do
          allow(DefaultVocabWordsReplacer).to receive(:new).and_return(replacer)
          params.merge!({ 'media_type' => 'vocab_list', 'program_id' => program.id.to_s })
          replacer
          @processor = MediaItemPublishProcessor.new(params)
        end

        it 'instantiates a DefaultVocabWordsReplacer object' do
          expect(DefaultVocabWordsReplacer).to receive(:new).with(media_item.full_filename, params['program_id'])
          @processor.process_request
        end

        it 'replaces current vocab words for the given program' do
          expect(replacer).to receive(:replace)
          @processor.process_request
        end
      end

      context "when media item's payload assignation is not succesful" do
        it 'sets the error returned by the retriever object' do
          allow(retriever).to receive(:result).and_return(nil)
          allow(retriever).to receive(:error).and_return('some error')
          new_processor = MediaItemPublishProcessor.new(params)
          new_processor.process_request
          expect(new_processor.errors).to include retriever.error
        end
      end
    end

    context 'when the media is on the cdn' do
      before do
        allow(media_item).to receive(:update).and_call_original
        allow(media_item).to receive(:payload=).and_call_original
      end

      context 'when the media_item record does not exist' do
        it 'creates the media_item' do
          allow(MediaItem).to receive(:find_by_id).and_return(nil)

          new_processor = MediaItemPublishProcessor.new(params)
          expect { new_processor.process_request }.to change(MediaItem, :count).by(1)
        end
      end

      context 'when the media_item record exists' do
        it 'updates the media item' do
          # create the record with the original params
          media_item.save
          # and then make like we're updating
          params.merge!(long_description: 'I describe the image')

          new_processor = MediaItemPublishProcessor.new(params)
          expect { new_processor.process_request }.to change(MediaItem, :count).by(0)
          expect(MediaItem.last.long_description).to eq params[:long_description]
        end
      end
    end
  end
end



describe MediaItemPublishProcessor::MediaFileRetriever do
  describe '#retrieve' do
    let(:media_file) { double('some_file', :size => 1024) }
    let(:http_response) { double('http_response', :code => '200', :body => media_file, :header => { 'content-length' => media_file.size }) }
    let(:valid_file_url) { 'https://cms.madeupurl.com/some_path' }

    before do
      allow(Net::HTTP).to receive(:start).and_return(http_response)
    end

    it 'raises an error when passed file url has no http header' do
      retriever = MediaItemPublishProcessor::MediaFileRetriever.new('cms.madeupurl.com/some_path' , media_file.size)
      expect{ retriever.retrieve }.to raise_error "Invalid url for file retrieval."
    end

    it 'starts a http connection to retrieve the file' do
      expect(Net::HTTP).to receive(:start).and_return(http_response)
      retriever = MediaItemPublishProcessor::MediaFileRetriever.new(valid_file_url, media_file.size)
      retriever.retrieve
    end

    it "adds an error to media item when response is not succesful" do
      allow(http_response).to receive(:code).and_return('404')
      retriever = MediaItemPublishProcessor::MediaFileRetriever.new(valid_file_url, media_file.size)
      retriever.retrieve
      expect(retriever.result).to be_nil
      expect(retriever.error).to eq('Connection failed')
    end

    context 'when request is successful' do
      it 'retrieves the media file set in payload_tempfile_path' do
        retriever = MediaItemPublishProcessor::MediaFileRetriever.new(valid_file_url, media_file.size)
        retriever.retrieve
        expect(retriever.result).to eq(media_file)
        expect(retriever.error).to be_nil
      end
    end
  end
end

