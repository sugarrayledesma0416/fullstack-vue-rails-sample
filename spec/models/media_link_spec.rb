describe MediaLink do
  let(:params) do
    { line: 'line', desired_media_type: 'image',
      desired_media_item_id: '1', spec: 'spec',
      instructor_uploaded: false }
  end

  describe '#open?' do
    it 'returns true if there is no media item id' do
      media_link = described_class.new(activity_id: 1, media_item_id: nil)
      expect(media_link).to be_open
    end

    it 'returns true if there is no associated media item' do
      media_link = described_class.new(activity_id: 1, media_item_id: 123)
      expect(media_link).to be_open
    end
  end

  describe '#desired_media_item_id=' do
    it 'sets media_item_id' do
      media_link = described_class.new(params)
      media_link.desired_media_item_id = 5
      expect(media_link.media_item_id).to eq(5)
    end
  end

  describe '#media_item' do
    it 'returns a InstructorMediaItem record if media is instructor uploaded.' do
      params.merge!(:instructor_uploaded => true)
      expect(InstructorMediaItem).to receive(:find_by_id).with(params[:desired_media_item_id])
      MediaLink.new(params).media_item
    end

    it 'returns a MediaItem record if media is not instructor uploaded.' do
      expect(MediaItem).to receive(:find_by_id).with(params[:desired_media_item_id])
      MediaLink.new(params).media_item
    end
  end

  describe '#transcript_mode' do
    it 'sets transcript_mode from initialization params' do
      params_with_transcript_mode = params.merge(transcript_mode: 'visible')
      media_link = described_class.new(params_with_transcript_mode)
      expect(media_link.transcript_mode).to eq('visible')
    end

    it 'sets transcript_mode from preview_attrs if available' do
      preview_attrs_with_transcript_mode = { transcript_mode: 'in_body' }
      params_with_preview_attrs = params.merge(preview_attrs: preview_attrs_with_transcript_mode)
      media_link = described_class.new(params_with_preview_attrs)
      expect(media_link.transcript_mode).to eq('in_body')
    end

    it 'prioritizes preview_attrs transcript_mode over direct transcript_mode param' do
      preview_attrs_with_transcript_mode = { transcript_mode: 'in_body' }
      params_with_both = params.merge(
        transcript_mode: 'visible',
        preview_attrs: preview_attrs_with_transcript_mode
      )
      media_link = described_class.new(params_with_both)
      expect(media_link.transcript_mode).to eq('in_body')
    end

    it 'allows setting transcript_mode after initialization' do
      media_link = described_class.new(params)
      media_link.transcript_mode = 'visible'
      expect(media_link.transcript_mode).to eq('visible')
    end
  end
end
