describe CmsActivityContent, core: true do
  let!(:xml_content) do
    File.read(Rails.root.join('spec', 'fixtures', 'xml', 'open_ended.xml'))
  end
  let(:activity) { build(:activity) }
  let(:json_activity) { build(:activity_with_json_content) }

  it "generates a CmsActivityContent object" do
    activity.save!
    expect(activity.activity_content).to be_a described_class
  end

  describe '#parse_content' do
    let(:xml_content) do
      %(<activity activity_type="blank" title="activity title" language="es">
          <dl/>
          <items/>
        </activity>)
    end

    it 'returns content_object from xml' do
      allow(activity.activity_content).to receive(:content).and_return(xml_content)
      activity.save!

      expect(activity).not_to receive(:build_from_json)
      expect(activity.content_object.class).to eq(
        MaestroActivityEngine::ActivityContent::Content
      )
    end
  end

  describe '#content_json' do
    let(:xml_content) do
      %(<activity activity_type="blank" title="activity title" language="es">
          <dl/>
          <items/>
        </activity>)
    end

    it 'returns content_json in stringified form for json activity' do
      json_activity.save!

      expect(json_activity.content_json.class).to eq(String)
    end

    it 'returns nil for xml activity' do
      allow(activity.activity_content).to receive(:content).and_return(xml_content)
      activity.save!

      expect(activity.content_json).to be_nil
    end
  end

  describe '#decode_content_html_entities' do
    let(:decoded_json_content) do
      File.read(File.join('spec', 'fixtures', 'json', 'decoded_assessment_builder_content.json'))
    end

    it 'validate the decoded content of the activity' do
      json_activity.save!
      decoded_content = JSON.parse(json_activity.activity_content.decode_content_html_entities)

      expect(
        decoded_content
      ).to eq(JSON.parse(decoded_json_content))
    end
  end

  describe "#content" do
    let(:blank_activity) { '<activity activity_type="blank"></activity>' }
    let(:cdn_cache) { double(ActivityCache, activity_get: blank_activity, cache_error: nil) }
    let(:s3) { double(Radner::S3Storage) }

    before do
      allow(M3::Application.config).to receive(:activity_cache).and_return(nil)
      allow(M3::Application.config).to receive(:statsd_client).and_return(nil)
      allow(ActivityCache).to receive(:new).with(
        M3::Application.config.cdn_cache, s3, STATS_PROXY
      ).and_return(cdn_cache)
      allow(Radner::S3Storage).to receive(:new).and_return(s3)
    end

    it "should read the contents from the cdn cache" do
      expected_filepath = Activity.filepath_from_revision_id(123456)
      activity.cms_revision_id = 123456
      activity.cdn = true
      expected_cache_key = activity.activity_content.send(:cache_key)
      expect(cdn_cache).to receive(:activity_get).with(
        expected_cache_key, expected_filepath
      ).and_return(blank_activity)

      activity.save!

      activity.content
    end

    it "creates a cdn cache connection" do
      expect(ActivityCache).to receive(:new).with(
        M3::Application.config.cdn_cache, s3, STATS_PROXY
      )
      activity.cms_revision_id = 123456
      activity.cdn = true
      activity.save!
    end
  end

  describe '#log_parse_warnings' do
    let(:warnings_content) do
      File.read(File.join(Rails.root, 'spec', 'fixtures', 'xml', 'parse_warnings_example.xml'))
    end

    before do
      activity.id = 123
      allow(activity.activity_content).to receive(:content).and_return(warnings_content)
      allow(Rails.logger).to receive(:warn)
    end

    it 'logs deprecation warnings' do
      activity.content_object #parses xml
      expect(Rails.logger).to have_received(:warn)
                          .with("DEPRECATION WARNING: <swf> has been deprecated "\
                          "and will be removed in a future update. (ID:123 L:7)")
      expect(Rails.logger).to have_received(:warn)
                          .with("DEPRECATION WARNING: <dl_audio> feature has "\
                          "been removed. Specifying this tag will not have any "\
                          "effect on the activity. (ID:123 L:4)")
    end

    it 'does not log other warnings' do
      parse_warning = MaestroActivityEngine::ParserWarning.new(12, 'warning message')
      allow(activity.activity_content).to receive(:parse_warnings)
                                    .and_return([parse_warning])
      activity.content_object #parses xml
      expect(Rails.logger).not_to have_received(:warn)
    end
  end

  describe '#content_filepath' do
    it 'calls filepath_from_revision_id with the cms revision id and instructor_created arg of false' do
      activity = build_stubbed(:activity, cms_revision_id: 1234, instructor_revision_id: nil)
      expect(Activity).to receive(:filepath_from_revision_id).with(1234, false, false).and_return('path')
      expect(activity.content_filepath).to eq 'path'

      activity = build_stubbed(:activity, cms_revision_id: 2345, instructor_revision_id: '')
      expect(Activity).to receive(:filepath_from_revision_id).with(2345, false, false).and_return('path')
      expect(activity.content_filepath).to eq 'path'
    end
  end
end
