describe InstructorMediaItem do
  let(:s3_bucket) do
    instance_double(
      Radner::S3Storage,
      move_file: nil,
      store_file_contents!: nil
    )
  end

  before do
    allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
  end

  shared_context 'with an audio recording' do
    let(:audio_original_filename) { 'uuid.wav' }
    let(:audio_temp_file_path) { 'instructor_created/audio_uploads/uuid.wav' }
    let(:audio_file_size) { 456 }

    let(:audio_item_attrs) do
      {
        media_type: 'audio',
        original_filename: audio_original_filename,
        temp_file_path: audio_temp_file_path
      }
    end

    before do
      allow(s3_bucket).to receive(:content_length).and_return(audio_file_size)
    end
  end

  shared_context 'with an image' do
    let(:temp_file_contents) { 'ABCDE' }
    let(:image_original_filename) { 'test.jpg' }
    let(:image_temp_file_path) do
      File.join('spec', 'fixtures', 'media_items', 'test.jpg')
    end
    let(:image_file_size) { 123 }
    let(:image_height) { 13 }
    let(:image_width) { 14 }

    let(:reference) do
      {
        'original_filename' => 'foo.txt',
        'temp_file_path' => image_temp_file_path,
        'instructor_id' => 1
      }
    end

    let(:magick_mock) do
      object_double(
        MiniMagick::Image.new('blah'),
        dimensions: [image_width, image_height],
        size: image_file_size,
        resize: nil,
        width: image_width
      )
    end

    before do
      allow(s3_bucket).to receive(:store_file_contents!)
      allow(s3_bucket).to receive(:fetch)
        .with(image_temp_file_path)
        .and_return(temp_file_contents)
      allow(MiniMagick::Image).to receive(:read).and_return(magick_mock)
      allow(MiniMagick::Image).to receive(:open).and_return(magick_mock)
      stub_request(:get, %r{https://media\.qa2\.vhlcentral\.com/instructor_created/.*})
        .to_return(status: 200, body: File.read(image_temp_file_path.to_s), headers: {})
    end
  end

  it 'includes MediaItemLocation' do
    expect(described_class.new).to be_kind_of MediaItemLocation
  end

  describe 'before saving' do
    context 'with an audio recording,' do
      include_context 'with an audio recording'

      it 'sets the extname' do
        media_item = create(:instructor_media_item, audio_item_attrs)
        expect(media_item.extname).to eq('.wav')
      end
    end

    context 'with an image file,' do
      include_context 'with an image'

      it 'sets the extname' do
        media_item = create(
          :instructor_media_item,
          original_filename: image_original_filename,
          temp_file_path: image_temp_file_path
        )
        expect(media_item.extname).to eq('.jpg')
      end

      it 'downcases the extname' do
        media_item = create(
          :instructor_media_item,
          original_filename: 'foo.TXT',
          temp_file_path: image_temp_file_path
        )
        expect(media_item.extname).to eq('.txt')
      end

      context 'with an image wider than 880px,' do
        let(:resized_contents) { temp_file_contents.reverse }

        before do
          allow(magick_mock).to receive(:width).and_return(1500)
          allow(magick_mock).to receive(:to_blob).and_return(resized_contents)
          described_class.create_from_temp_file(reference)
        end

        it 'reads the original image' do
          expect(MiniMagick::Image).to have_received(:read)
            .with(temp_file_contents)
        end

        it 'resizes the image to 880px max' do
          expect(magick_mock).to have_received(:resize)
            .with(described_class::MAX_IMAGE_WIDTH)
        end

        it 'extracts the resized image as a blob' do
          expect(magick_mock).to have_received(:to_blob)
        end

        it 'writes the resized blob to s3' do
          expect(s3_bucket).to have_received(:store_file_contents!)
            .with(image_temp_file_path, resized_contents)
        end
      end
    end
  end

  describe 'after saving' do
    context 'with an audio recording,' do
      include_context 'with an audio recording'

      let(:media_item) do
        build(:instructor_media_item, audio_item_attrs)
      end

      before { media_item.save }

      it 'moves the file from the S3 temp path to its final path' do
        expect(s3_bucket).to have_received(:move_file)
          .with(audio_temp_file_path, media_item.file_path)
      end

      it 'retrieves the file size of the media item from the s3 bucket' do
        expect(s3_bucket).to have_received(:content_length)
          .with(media_item.file_path)
      end

      it 'stores the file size of the media item' do
        media_item.reload
        expect(media_item.size).to eq(audio_file_size)
      end
    end

    context 'with an image file,' do
      include_context 'with an image'

      let(:media_item) do
        build(
          :instructor_media_item,
          original_filename: image_original_filename,
          temp_file_path: image_temp_file_path
        )
      end

      before { media_item.save }

      it 'downloads a local copy of the media item' do
        expect(s3_bucket).to have_received(:fetch)
          .with(image_temp_file_path)
      end

      it 'loads the local copy of the media item as a MiniMagic image' do
        expect(MiniMagick::Image).to have_received(:read)
          .with(temp_file_contents)
      end

      it 'reads the size of the media item from the MiniMagick image' do
        expect(magick_mock).to have_received(:size)
      end

      it 'stores the height and width of the media item' do
        media_item.reload
        expect(media_item).to have_attributes(
          height: image_height,
          width: image_width
        )
      end

      it 'stores the file size of the media item' do
        media_item.reload
        expect(media_item.size).to eq(image_file_size)
      end

      it 'moves the file from the S3 temp path to its final path' do
        expect(s3_bucket).to have_received(:move_file)
          .with(image_temp_file_path, media_item.file_path)
      end
    end
  end

  describe '.create_from_temp_file' do
    include_context 'with an image'

    it 'creates a new record with the specified params' do
      allow(described_class).to receive(:create).and_call_original
      described_class.create_from_temp_file(reference)

      expected_reference = reference.symbolize_keys.merge(media_type: 'image')
      expect(described_class).to have_received(:create)
        .with(hash_including(expected_reference))
    end
  end

  describe '#file_path' do
    context 'with an image file,' do
      include_context 'with an image'

      let(:media_item) do
        create(:instructor_media_item, temp_file_path: image_temp_file_path)
      end

      let(:filename) { format('%08d', media_item.id) + media_item.extname }

      it 'returns the cdn filepath' do
        expect(media_item.file_path).to eq(
          File.join('instructor_created', 'images', '0000', filename).to_s
        )
      end
    end
  end

  describe '#public_url_for_arc' do
    include_context 'with an audio recording'

    it 'returns the public filename' do
      media_item = create(:instructor_media_item, audio_item_attrs)

      expect(media_item.public_url_for_arc).to eq(media_item.public_filename)
    end
  end
end
