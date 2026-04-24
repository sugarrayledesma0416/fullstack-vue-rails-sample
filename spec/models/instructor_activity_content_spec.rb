describe InstructorActivityContent, core: true  do
  let(:xml_content) do
    File.read(File.join('spec', 'fixtures', 'xml', 'open_ended.xml'))
  end

  let(:new_content) do
    File.read(File.join('spec', 'fixtures', 'xml', 'dropdown.xml'))
  end

  let(:activity) { build(:instructor_generated_activity) }

  it 'generates an InstructorActivityContent object' do
    activity.save
    expect(activity.activity_content).to be_a described_class
  end

  describe '#store_content' do
    let(:s3) { double(Radner::S3Storage, file_exist?: false) }

    before do
      allow(activity.activity_content).to receive(:s3_bucket).and_return(s3)
    end

    context 'when on a live server,' do
      before do
        allow(Rails.env).to receive(:live?).and_return(true)
      end

      it 'stores activity xml on s3' do
        expect(s3).to receive(:store_file_contents!).and_return(true)
        expect(s3).to_not receive(:upload_error)

        activity.activity_content.store_content(new_content)
      end

      it 'raises an error on failure' do
        upload_error = StandardError.new('S3 Fail')

        expect(s3).to receive(:store_file_contents!).and_raise(upload_error)

        expect do
          activity.activity_content.store_content(new_content)
        end.to raise_error(upload_error)
      end
    end

    context 'when not on a live server,' do
      let(:file_handle) { double(File, write: true, close: true) }

      before do
        allow(Rails.env).to receive(:live?).and_return(false)
      end

      it 'stores activity xml on disk' do
        expect(activity.activity_content).to receive(:store_file_contents)

        activity.activity_content.store_content(new_content)
      end

      it 'does not overwrite the revision file if it exists' do
        allow(File).to receive(:exist?)
          .with(activity.activity_content.content_filepath)
          .and_return(true)
        expect(File).to_not receive(:write)

        activity.activity_content.store_content(new_content)
      end

      it 'creates the filepath and writes the file' do
        expect(File).to receive(:write)
          .with(activity.activity_content.content_filepath, new_content)
        activity.activity_content.store_content(new_content)
      end
    end
  end

  describe '#generate_content_json' do
    let(:json) { 'json' }
    let(:content_object) do
      double(MaestroActivityEngine::ActivityContent::Content, to_json: json)
    end

    before do
      allow(activity).to receive(:content_object) { content_object }
    end

    it 'converts the content object to json' do
      expect(content_object).to receive(:to_json).with(indent: 2) { json }
      expect(activity.generate_content_json).to eq(json)
    end
  end

  describe '#content_json' do
    let(:multi_answer_exam_xml) do
      File.read(
        File.join('spec', 'fixtures', 'xml', 'exam_with_multiple_answer.xml')
      )
    end

    let(:current_revision) { instance_double(InstructorActivityRevision) }

    let(:json) do
      File.read(
        File.join('spec', 'fixtures', 'instructor_created_activity_content.json')
      )
    end

    let(:activity) { build(:instructor_generated_activity) }
    let(:s3) { instance_double(Radner::S3Storage) }

    before do
      allow(Radner::S3Storage).to receive(:new).and_return(s3)
      allow(s3).to receive(:fetch).and_return(json)
    end

    it 'can parse an exam that includes a multiple-answer activity' do
      allow(activity.activity_content).to receive(:content).and_return(
        multi_answer_exam_xml
      )
      json = activity.content_object.to_json

      content = described_class.new(1, false, 2)
      allow(content).to receive(:content_json).and_return(json)

      expect(
        content.parse_content.activities.flat_map(&:items).map(&:class)
      ).to eq(
        [
          MaestroActivityEngine::ActivityContent::Reference::Exam,
          MaestroActivityEngine::ActivityContent::MultipleChoice::Item,
          MaestroActivityEngine::ActivityContent::Reference::Exam,
          MaestroActivityEngine::ActivityContent::MultipleAnswer::Item
        ]
      )
    end

    it 'returns the content of the current revision based on ' \
       'instructor_revision_id' do
      allow(activity).to receive(:content_json).and_return(json)
      allow(current_revision).to receive(:content_json).and_return(json)
      allow(InstructorCreatedActivity).to receive(:find_by)
        .with(id: activity.instructor_revision_id)
        .and_return(current_revision)
      activity.save
      expect(activity.content_json).not_to be_nil
      expect(activity.content_json).to eq(current_revision.content_json)
    end

    it 'returns nil when does not have current revision' do
      activity.save
      allow(InstructorCreatedActivity).to receive(:find_by)
        .with(id: activity.instructor_revision_id)
        .and_return(nil)
      expect(activity.content_json).to be_nil
    end
  end

  describe '#parse_content' do
    let(:exam_content) { MaestroActivityEngine::ActivityContent::ExamContent }
    let(:activity) { build(:activity) }

    let(:json) do
      File.read(
        File.join('spec', 'fixtures', 'instructor_created_activity_content.json')
      )
    end

    let(:xml_content) do
      %(
        <activity activity_type="blank" title="activity title" language="es">
          <dl/>
          <items/>
        </activity>
      )
    end

    it 'returns content_object from json' do
      allow(InstructorActivityRevision).to receive(:find_by)
        .and_return(double(InstructorActivityRevision, content_json: json))
      allow(activity).to receive(:content).and_return(json)

      activity.instructor_revision_id = 1234
      activity.save

      expect(activity.parse_content.class).to eq(exam_content)
    end

    it 'returns content_object from xml' do
      allow(activity.activity_content).to receive(:content).and_return(xml_content)
      activity.save

      expect(activity).to_not receive(:build_from_json)
      expect(activity.content_object.class).to eq(MaestroActivityEngine::ActivityContent::Content)
    end
  end

  describe "#content" do
    let(:blank_activity) { '<activity activity_type="blank"></activity>' }
    let(:cdn_cache) { double(ActivityCache, activity_get: blank_activity, cache_error: nil) }
    let(:s3) { double(Radner::S3Storage) }

    before do
      allow(M3::Application.config).to receive(:cdn_cache).and_return(nil)
      allow(M3::Application.config).to receive(:statsd_client).and_return(nil)
      allow(ActivityCache).to receive(:new).with(
        M3::Application.config.cdn_cache, s3, STATS_PROXY
      ).and_return(cdn_cache)
      allow(Radner::S3Storage).to receive(:new).and_return(s3)
    end

    context 'when on a live server,' do
      before do
        allow(Rails.env).to receive(:live?).and_return(true)
      end

      it "reads the contents from the cdn cache" do
        expected_filepath = Activity.filepath_from_revision_id(123456)
        activity = build(:activity, cms_revision_id: 123456, cdn: true)

        expected_cache_key = activity.activity_content.send(:cache_key)
        allow(cdn_cache).to receive(:activity_get).and_return(blank_activity)

        activity.content

        expect(cdn_cache).to have_received(:activity_get).with(
          expected_cache_key, expected_filepath
        )
      end

      it 'creates a cdn cache connection' do
        activity = build(:activity, cms_revision_id: 123456, cdn: true)
        activity.save!
        expect(ActivityCache).to have_received(:new).with(
          M3::Application.config.cdn_cache, s3, STATS_PROXY
        )
      end
    end

    context 'when not on a live server,' do
      before do
        allow(File).to receive(:read).and_return(blank_activity)
      end

      it 'reads the contents from a disk file if cdn is false' do
        allow(File).to receive(:exist?).and_return(true)
        activity = create(:activity, cms_revision_id: 123456, cdn: false)

        expect(File).to receive(:read)
          .with(activity.activity_content.content_filepath)
          .and_return(blank_activity)
        activity.content
      end
    end
  end

  describe '#content_filepath' do
    it 'calls filepath_from_revision_id with the instructor_revision_id ' \
       'and instructor_created arg if true' do
      activity = build_stubbed(
        :activity,
        cms_revision_id: 1234,
        instructor_revision_id: 5678
      )
      expect(Activity).to receive(:filepath_from_revision_id)
        .with(5678, true, false)
        .and_return('path')
      expect(activity.content_filepath).to eq 'path'
    end
  end
end
