describe RecordingPath do
  let(:activity) { create(:activity) }
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:course) { create(:course) }
  let(:recordable) { ActivityNote.new }
  let(:recording) { create(:recording) }
  let(:recorded) do
    ActivityNote.create!(
      recording: recording,
      activity: activity,
      user_id: instructor.id,
      focused_course: course,
      program: program
    )
  end

  describe '#recording_path=' do
    context 'when a recording exists' do
      context 'when path is not present' do
        it 'deletes the recording' do
          recorded.recording_path = ''
          expect(recorded.recording).to be_nil
        end

        it 'updates the recording_id to nil' do
          recorded.recording_path = ''
          expect(recorded.recording_id).to be_nil
        end
      end

      it 'does nothing is path has not changed' do
        recorded.recording_path = recording.recording_path
        expect(recorded.recording).to eq(recording)
        expect(recorded.recording_path).to eq(recording.recording_path)
      end

      it 'updates the recording record if path has changed' do
        recorded.recording_path = 'my/new/path'
        expect(recorded.recording.recording_path).to eq('my/new/path')
      end
    end

    context 'when no recording exists' do
      it 'does nothing if path is not present' do
        recordable.recording_path = ''
        expect(recordable.recording).to be_nil
      end

      it 'builds a recording record if path is present' do
        recordable.recording_path = 'my/new/path'
        expect(recordable.recording_path).to eq('my/new/path')
      end
    end
  end

  describe '#recording_path' do
    context 'when recording exists' do
      it 'returns the recording path' do
        expect(recorded.recording_path).to eq(recording.recording_path)
      end
    end

    context 'when recording does not exist' do
      it 'returns nil' do
        expect(recordable.recording_path).to be_nil
      end
    end
  end
end
