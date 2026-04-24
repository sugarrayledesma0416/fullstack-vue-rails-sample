describe ActivityNote do
  let(:recording) { create(:recording) }
  let(:video_recording) { create(:video_recording) }

  describe 'validations' do
    it 'requires non-blank body_text or recording_path' do
      expect(build(:activity_note, body_text: nil, recording_path: '')).not_to be_valid
      expect(build(:activity_note, body_text: '', recording_path: nil)).not_to be_valid
      expect(build(:activity_note, body_text: nil, recording_path: '/my-path')).to be_valid
      expect(build(:activity_note, body_text: 'foo', recording_path: nil)).to be_valid
    end

    it 'requires body_text to contain some non-whitespace content' do
      body_text = "\n\t<p>\t&nbsp;\n</p> \n \t"
      expect(build(:activity_note, body_text: body_text)).not_to be_valid
    end
  end

  describe 'scopes' do
    describe '.by_activity' do
      it 'returns only notes for the specified activity' do
        activity = create(:activity)
        target_note = create(:activity_note, activity: activity)
        other_activity_note = create(:activity_note, activity: create(:activity))
        expect(described_class.by_activity(activity)).to eq([target_note])
      end
    end

    describe '.by_instructor' do
      it 'returns only notes for the specified instructor' do
        instructor = create(:instructor)
        target_note = create(:activity_note, instructor: instructor)
        other_instructor_note = create(:activity_note, instructor: create(:instructor))
        expect(described_class.by_instructor(instructor)).to eq([target_note])
      end
    end
  end

  describe '#video_recording_path=' do
    context 'when a video recording exists' do
      let(:activity_note) do
        build(:activity_note, video_recording: video_recording)
      end

      before do
        activity_note.save!
      end

      context 'when path is not present' do
        it 'deletes the recording' do
          activity_note.video_recording_path = ''
          expect(activity_note.video_recording).to be_nil
        end

        it 'updates the recording_id to nil' do
          activity_note.video_recording_path = ''
          expect(activity_note.video_recording_id).to be_nil
        end
      end

      it 'does nothing is path has not changed' do
        activity_note.video_recording_path = video_recording.recording_path
        expect(activity_note.video_recording).to eq(video_recording)
        expect(activity_note.video_recording_path).to eq(video_recording.recording_path)
      end

      it 'updates the recording record if path has changed' do
        activity_note.video_recording_path = 'my/new/path'
        expect(activity_note.video_recording.recording_path).to eq('my/new/path')
      end
    end

    context 'when no recording exists' do
      let(:activity_note) { described_class.new }

      it 'does nothing if path is not present' do
        activity_note.video_recording_path = ''
        expect(activity_note.video_recording).to be_nil
      end

      it 'builds a recording record if path is present' do
        activity_note.video_recording_path = 'my/new/path'
        expect(activity_note.video_recording_path).to eq('my/new/path')
      end
    end
  end

  describe '#as_json' do
    it 'serializes recording_path' do
      activity_note = described_class.new
      allow(activity_note).to receive(:recording).and_return(recording)
      expect(activity_note.to_json['recording_path']).to eq(recording.recording_path)
    end
  end
end
