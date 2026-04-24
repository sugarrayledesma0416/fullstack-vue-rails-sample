describe MediaItem, core: true do
  before do
    FakeFS::FileSystem.clone File.join(Rails.root, 'spec/fixtures')
  end

  it 'includes MediaItemLocation' do
    expect(MediaItem.new).to be_kind_of MediaItemLocation
  end

  it 'should be unzippable' do
    expect(MediaItem.new).to be_a(Unzippable)
  end

  describe 'named scopes' do
    describe '.audio_or_video' do
      it 'returns audio or video media items' do
        audio_item = create(:media_item, :media_type => 'audio')
        video_item = create(:media_item, :media_type => 'video')
        other_item = create(:media_item, :media_type => 'other')
        expect(MediaItem.audio_or_video).to match_array([audio_item, video_item])
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save' do
      it 'saves the alt_tag value on images' do
        image = build(:media_item_image, alt_tag: 'picture of test')
        image.save
        expect(MediaItem.find(image.id).alt_tag).to eq 'picture of test'
      end

      it 'sets the alt_tag to nil when media is not an image' do
        video = build(:media_item_video, alt_tag: 'will not save this')
        video.save
        expect(MediaItem.find(video.id).alt_tag).to be_nil
      end
    end
  end

  describe '#server_url' do
    let(:media_item) do
      MediaItem.new(filename: 'sample_filename.jpg', media_type: 'image')
    end

    it 'returns passed url if media is not in cdn' do
      allow(media_item).to receive(:cdn?).and_return(false)
      result = media_item.server_url('http://example.com/')
      expect(result).to eq('http://example.com/')
    end

    it 'returns cdn url if media is in cdn' do
      allow(media_item).to receive(:cdn?).and_return(true)
      result = media_item.server_url('http://example.com/')
      expect(result).to eq(MediaItem::CDN_URL_PREFIX)
    end
  end

  describe '#public_filename_for_arc' do
    let(:media_item) do
      MediaItem.new(filename: 'sample_filename.jpg', media_type: 'image')
    end

    before do
      allow(media_item).to receive(:public_filename).and_return('/path/to/file')
    end

    it 'returns public_filename without cdn prefix' do
      allow(media_item).to receive(:cdn?).and_return(false)
      expect(media_item.public_filename_for_arc).not_to include MediaItem::CDN_URL_PREFIX
    end
  end

  describe '#public_filename' do
    let(:media_item) do
      described_class.new(filename: 'sample_filename.jpg', media_type: 'image')
    end

    before do
      media_item.id = 101_010
      media_item.save!
    end

    context 'when the media item has no revision id' do
      context 'when the item has not been uploaded to the cdn' do
        it 'returns a relative url including the media type, the first 4 ' \
           'digits of the id, and the original filename' do
          expect(media_item.public_filename).to eq(
            "/media_items/#{Rails.env}#{ENV['TEST_ENV_NUMBER']}/" \
            'images/0010/sample_filename.jpg'
          )
        end
      end

      context 'when the item has been uploaded to the cdn' do
        it 'returns a full url at the cdn host, including the media type, ' \
           'the first 4 digits of the id, and the original filename' do
          media_item.cdn = true
          expect(media_item.public_filename).to eq(
            "#{MediaItem::CDN_URL_PREFIX}/images/0010/sample_filename.jpg"
          )
        end
      end
    end

    context 'when the media item has a revision id' do
      before do
        media_item.revision_id = 456_789
      end

      context 'when the item has not been uploaded to the cdn' do
        it 'returns a relative url including the media type, id, ' \
           'revision id, and the extension of the original filename' do
          expect(media_item.public_filename).to eq(
            "/media_items/#{Rails.env}#{ENV['TEST_ENV_NUMBER']}" \
            '/images/m00101010_r00456789.jpg'
          )
        end
      end

      context 'when the item has been uploaded to the cdn' do
        it 'returns a full url at the cdn host, including the media type, ' \
           'id, revision id, and the extension of the original filename' do
          media_item.cdn = true
          expect(media_item.public_filename).to eq(
            "#{MediaItem::CDN_URL_PREFIX}/images/m00101010_r00456789.jpg"
          )
        end
      end
    end
  end

  describe '#full_filename' do
    context 'when the file has not been uploaded to the cdn' do
      it 'points to the public directory' do
        item = create(:media_item)
        expect(item.full_filename).to match(/public#{item.public_filename}/)
      end
    end

    context 'when the file has been uploaded to the cdn' do
      it 'returns nil' do
        item = create(:media_item, cdn: true)
        expect(item.full_filename).to be_nil
      end
    end
  end

  describe '#aspect_ratio' do
    context 'when media item has a 4:3 aspect ratio,' do
      it 'returns 4_by_3 as a string' do
        expect(MediaItem.new(width: 400, height: 320).aspect_ratio).to eq('4_by_3')
        expect(MediaItem.new(width: 130, height: 120).aspect_ratio).to eq('4_by_3')
        expect(MediaItem.new(width: 140, height: 120).aspect_ratio).to eq('4_by_3')
      end
    end

    context 'when media item has a 16:9 aspect ratio,' do
      it 'returns 16_by_9 as a string' do
        expect(MediaItem.new(width: 160, height: 110).aspect_ratio).to eq('16_by_9')
        expect(MediaItem.new(width: 170, height: 120).aspect_ratio).to eq('16_by_9')
        expect(MediaItem.new(width: 180, height: 120).aspect_ratio).to eq('16_by_9')
      end
    end

    context 'when media item has an unknown aspect ratio,' do
      it 'raises an error' do
        expect{ MediaItem.new(width: 129, height: 120).aspect_ratio }
          .to raise_error(RuntimeError, /Unsupported aspect ratio/)
        expect{ MediaItem.new(width: 141, height: 120).aspect_ratio }
          .to raise_error(RuntimeError, /Unsupported aspect ratio/)
        expect{ MediaItem.new(width: 169, height: 120).aspect_ratio }
          .to raise_error(RuntimeError, /Unsupported aspect ratio/)
        expect{ MediaItem.new(width: 181, height: 120).aspect_ratio }
          .to raise_error(RuntimeError, /Unsupported aspect ratio/)
      end
    end
  end

  describe "#payload=" do
    include FakeFS::SpecHelpers

    before do
      FakeFS::FileSystem.clone File.join(Rails.root, 'spec/fixtures')
      Dir.chdir Rails.root
    end

    context 'when media item is an image' do
      let(:media_item) { MediaItem.new(:filename => 'model_spec_image.jpg', :media_type => 'image') }
      let(:magick_mock) do
        object_double(
          MiniMagick::Image.new('blah'),
          dimensions: [100, 200]
        )
      end

      before do
        allow(MiniMagick::Image).to receive(:open).and_return(magick_mock)
        media_item.id = 101010
        media_item.save!
      end

      it "writes images to the /images directory" do
        media_item.payload = 'valid_payload_content'
        id_string  = ("%08d" % media_item.id)
        filepath = Rails.root.join(
          'public',
          'media_items',
          "#{Rails.env}#{ENV['TEST_ENV_NUMBER']}",
          'images',
          id_string[0..3],
          'model_spec_image.jpg'
        )
        expect(File.exist?(filepath)).to be_truthy
        expect(File.read(filepath)).to eq('valid_payload_content')
      end

      it 'sets values for width and height attributes of the image' do
        expect(media_item).to receive(:set_dimensions)
        media_item.payload = 'valid_payload_content'
      end
    end

    it "writes videos to the /video directory" do
      media_item = MediaItem.new(:filename => 'model_spec_video.flv', :media_type => 'video')
      media_item.id = 101010
      media_item.save!
      media_item.payload = 'valid_payload_content'
      id_string  = ("%08d" % media_item.id)
      filepath = File.join(
        'public',
        'media_items',
        "#{Rails.env}#{ENV['TEST_ENV_NUMBER']}",
        'video',
        id_string[0..3],
        'model_spec_video.flv'
      )
      expect(File.exist?(filepath)).to be_truthy
    end

    context "when media item is a vocab_group," do
      let(:media_item){ MediaItem.new(:filename => 'test.vocab_group.zip', :media_type => 'vocab_group') }

      before do
        media_item.id = 101010
        media_item.save!
      end

      it "unzip without sub directories" do
        expect(media_item).to receive(:unzip_without_subdirs)
        media_item.payload = get_reading_zip_payload
      end

      it "removes old csv files from directory" do
        file_to_remove = File.join(Rails.root, media_item.send(:base_dir), 'test_csv.csv')
        zip_filename = 'spec/fixtures/media_items/test.vocab_group.zip'
        FileUtils.mkdir_p(File.dirname(file_to_remove))

        File.open(file_to_remove, 'w' )
        allow(media_item).to receive(:unzip_without_subdirs)
        expect(File.exist?(file_to_remove)).to be_truthy

        media_item.payload = File.read(zip_filename)
        expect(File.exist?(file_to_remove)).to be_falsey
      end
    end

    context "when media item is a vocab_tutorial," do
      let(:media_item){ MediaItem.new(:filename => 'tutorial_vocab.zip', :media_type => 'vocab_tutorial') }

      before do
        media_item.id = 101010
        media_item.save!
      end

      it "unzip with sub directories" do
        expect(media_item).to receive(:unzip_with_subdirs)
        media_item.payload = get_reading_zip_payload
      end
    end

    context 'when the media item is an HTML5 vocab tutorial' do
      it 'unzips the media item file' do
        media_item = create(:media_item,
                             filename: 'vocab_tutorial_html5.zip',
                             media_type: 'vocab_tutorial_html5')

        allow(media_item).to receive(:store_unprocessed_payload).and_return(true)

        expect(FileUtils).to receive(:makedirs).twice
        expect(media_item).to receive(:unzip_with_subdirs)

        media_item.payload = get_reading_zip_payload
      end
    end
  end

  describe "#json_version" do
    context "when media item is a stl file," do
      let (:media_item) { MediaItem.new(:filename => 'file.stl', :media_type => 'subtitle') }
      let (:media_item_id) { 101010 }
      let (:json_version_filename) { "/subtitle/0010/file.js" }
      let (:media_item_dir) { File.dirname( media_item.cdn_target_filename ) }

      before do
        media_item.id = media_item_id
        media_item.save!
      end

      it "returns the subtitle file name with .js extension" do
        expect(media_item.json_version).to eq(MediaItem::CDN_URL_PREFIX + json_version_filename)
      end
    end

    context "when media item is an xml file," do
      let (:media_item) { MediaItem.new(:filename => 'file.xml', :media_type => 'xml') }
      let (:media_item_id) { 101010 }
      let (:json_version_filename) { "/xml/0010/file.js" }
      let (:media_item_dir) { File.dirname( media_item.cdn_target_filename ) }

      before do
        media_item.id = media_item_id
        media_item.save!
      end

      it "returns the subtitle file name with .js extension" do
        expect(media_item.json_version).to eq(MediaItem::CDN_URL_PREFIX + json_version_filename)
      end
    end
  end

  describe "#vtt_version" do
    context "when media item is a stl file," do
      let (:media_item) { MediaItem.new(:filename => 'file.stl', :media_type => 'subtitle') }
      let (:media_item_id) { 101010 }
      let (:vtt_version_filename) { "/subtitle/0010/file.vtt" }
      let (:media_item_dir) { File.dirname( media_item.cdn_target_filename ) }

      before do
        media_item.id = media_item_id
        media_item.save!
      end

      it "returns the subtitle file name with .vtt extension" do
        expect(media_item.vtt_version).to eq(MediaItem::CDN_URL_PREFIX + vtt_version_filename)
      end
    end

    context "when media item is an xml file," do
      let (:media_item) { MediaItem.new(:filename => 'file.xml', :media_type => 'xml') }
      let (:media_item_id) { 101010 }
      let (:vtt_version_filename) { "/xml/0010/file.vtt" }
      let (:media_item_dir) { File.dirname( media_item.cdn_target_filename ) }

      before do
        media_item.id = media_item_id
        media_item.save!
      end

      it "returns the subtitle file name with .vtt extension" do
        expect(media_item.vtt_version).to eq(MediaItem::CDN_URL_PREFIX + vtt_version_filename)
      end
    end
  end

  describe '#unzipped_cdn_directory' do
    context 'with a flash_reading media_item,' do
      let(:media_item) do
        build_stubbed(:media_item, id: 123_456, media_type: 'flash_reading')
      end

      context 'when the media item is on the cdn,' do
        before { media_item.cdn = true }

        it 'returns a directory including the media type, first 4 digits of ' \
           'the id, and last 4 digits of the id when revision_id is blank' do
          expect(media_item.unzipped_cdn_directory).to eq(
            "#{MediaItem::CDN_URL_PREFIX}/flash_reading/" \
            '0012/3456'
          )
        end

        it 'returns a directory including the media type, the id, and the ' \
           'revision id when revision_id is not blank' do
          media_item.revision_id = 456_789
          expect(media_item.unzipped_cdn_directory).to eq(
            "#{MediaItem::CDN_URL_PREFIX}/flash_reading/" \
            'm00123456_r00456789'
          )
        end
      end

      context 'when the media item is not on the cdn,' do
        before { media_item.cdn = false }

        it 'returns nil when revision id is not set' do
          expect(media_item.unzipped_cdn_directory).to be_nil
        end

        it 'returns nil when revision id is set' do
          media_item.revision_id = 456_789
          expect(media_item.unzipped_cdn_directory).to be_nil
        end
      end
    end

    it 'returns nil with a non zip-type media_item' do
      audio = build_stubbed(:media_item_audio, cdn: true)
      video = build_stubbed(:media_item_video, cdn: true)
      image = build_stubbed(:media_item_image, cdn: true)
      expect(
        [audio, video, image].map(&:unzipped_cdn_directory)
      ).to eq([nil, nil, nil])
    end
  end

  describe '#tutorial_id' do
    let(:media_item) { build_stubbed(:media_item, media_type: 'vocab_tutorial') }

    context 'when cdn is true' do
      it 'returns the content of the tutorial_id.txt file' do
        media_item.cdn = true
        expected_url = "#{MediaItem::CDN_URL_PREFIX}/vocab_tutorial/#{media_item.dir_chunk}/#{media_item.subdir_chunk}/data/tutorial_id.txt"
        expected_tutorial_id = 'c103'
        expect(URI).to receive(:parse).with(expected_url).and_return(expected_url)
        expect(Net::HTTP).to receive(:get).with(expected_url).and_return(expected_tutorial_id)
        expect(media_item.tutorial_id).to eq expected_tutorial_id
      end
    end

    context 'when cdn is false' do
      it 'returns nil' do
        expect(media_item.tutorial_id).to be_nil
      end
    end
  end

  describe '#csv_content' do
    let(:media_item) { build_stubbed(:media_item, media_type: 'vocab_group') }

    context 'when cdn is true' do
      let(:redis_cache) { double('Redis', get: nil, set: nil) }
      let(:expected_filename_url) { "#{MediaItem::CDN_URL_PREFIX}/vocab_group/#{media_item.dir_chunk}/#{media_item.subdir_chunk}/csv_filename.txt" }
      let(:expected_content_url) { "#{MediaItem::CDN_URL_PREFIX}/vocab_group/#{media_item.dir_chunk}/#{media_item.subdir_chunk}/VIS5e_L01_02_voc.csv" }
      let(:expected_csv_filename) { 'VIS5e_L01_02_voc.csv' }
      let(:expected_csv_content) { 'expected_csv_content' }
      let(:cache_key) { "media_item:#{media_item.id}#{media_item.updated_at.to_i}" }

      before do
        allow(M3::Application.config).to receive(:cdn_cache).and_return(redis_cache)
        media_item.cdn = true
        allow(URI).to receive(:parse).with(expected_filename_url).and_return(expected_filename_url)
        allow(Net::HTTP).to receive(:get).with(expected_filename_url).and_return(expected_csv_filename)
      end

      context 'if data is not in the redis cache' do
        it 'returns the content of the csv_filename.txt file' do
          expect(URI).to receive(:parse).with(expected_content_url).and_return(expected_content_url)
          expect(Net::HTTP).to receive(:get).with(expected_content_url).and_return(expected_csv_content)
          expect(media_item.csv_content).to eq [[expected_csv_content]]
        end

        it 'saves the result in the redis cache' do
          allow(URI).to receive(:parse).with(expected_content_url).and_return(expected_content_url)
          allow(Net::HTTP).to receive(:get).with(expected_content_url).and_return(expected_csv_content)
          expect(redis_cache).to receive(:set).with(cache_key, expected_csv_content)
          media_item.csv_content
        end
      end

      context 'if data is in the redis cache' do
        it 'obtains the data from redis' do
          expect(redis_cache).to receive(:get).with(cache_key).and_return(expected_csv_content)
          expect(media_item.csv_content).to eq [[expected_csv_content]]
        end
      end
    end

    context 'when cdn is false' do
      it 'returns nil' do
        expect(media_item.csv_content).to be_nil
      end
    end
  end

  describe '#base_content_folder' do
    let(:media_item) { build_stubbed(:media_item, media_type: 'vocab_tutorial') }

    context 'when cdn is true' do
      it 'returns the content of the base_content_folder.txt file' do
        media_item.cdn = true
        expected_url = "#{MediaItem::CDN_URL_PREFIX}/vocab_tutorial/#{media_item.dir_chunk}/#{media_item.subdir_chunk}/base_content_folder.txt"
        expected_base_content_folder = 'VIS5e_L01_02_voc_tutorial.html5_vocab_tutorial'
        expect(URI).to receive(:parse).with(expected_url).and_return(expected_url)
        expect(Net::HTTP).to receive(:get).with(expected_url).and_return(expected_base_content_folder)
        expect(media_item.base_content_folder).to eq expected_base_content_folder
      end
    end

    context 'when cdn is false' do
      it 'returns nil' do
        expect(media_item.base_content_folder).to be_nil
      end
    end
  end

  describe '#public_dir' do
    let(:media_item) do
      build_stubbed(
        :media_item,
        media_type: 'vocab_tutorial',
        cdn: true
      )
    end

    context 'when there is no revision_id' do
      it 'returns the non-revision path' do
        media_item.revision_id = nil
        expect(media_item.public_dir).to match /https:\/\/.+\/vocab_tutorial\/\d+\/\d+/
      end
    end

    context 'when the revision_id is set' do
      it 'returns the revision specific path' do
        media_item.revision_id = 161314
        expect(media_item.public_dir).to match /https:\/\/.+\/vocab_tutorial\/m\d+_r\d+/
      end
    end
  end

  describe '#unzipped_directory' do
    let(:media_item) do
      build_stubbed(:media_item, media_type: 'vocab_tutorial')
    end

    context 'when cdn is true' do
      it 'returns the unzipped cdn directory path' do
        media_item.cdn = true
        expect(media_item.unzipped_directory).to eq(
          media_item.unzipped_cdn_directory
        )
      end
    end

    context 'when cdn is false' do
      it 'returns the local path where the file was unzipped' do
        expect(media_item.unzipped_directory).to eq media_item.public_dir
      end
    end
  end

  def get_reading_zip_payload
    zip_filename = 'spec/fixtures/media_items/flash_reading.zip'
    File.read(zip_filename)
  end

end
