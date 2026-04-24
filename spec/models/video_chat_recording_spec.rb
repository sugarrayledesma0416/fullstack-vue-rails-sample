# frozen_string_literal: true

require 'securerandom'

describe VideoChatRecording, core: true do
  let(:user_1) do
    { 'id' => '1',
      'section_id' => rand,
      'video' => { 'video/mp4' => 'path/to/video/archive.mp4',
                   'video/webm' => 'path/to/video/archive.webm' } }
  end

  let(:user_2) do
    { 'id' => '2',
      'section_id' => rand,
      'video' => { 'video/mp4' => 'path/to/video/archive.mp4',
                   'video/webm' => 'path/to/video/archive.webm' } }
  end

  let(:dynamo_object) do
    { 'archive_id' => SecureRandom.uuid,
      'school_id' => rand,
      'course_id' => rand,
      'user_1' => user_1,
      'user_2' => user_2 }
  end

  describe '#primary_key' do
    it 'returns the primary key following the expected format by the dynamo wrapper' do
      recording = described_class.new(object: dynamo_object, user_id: 1)

      expect(recording.primary_key).to eq([{ archive_id: dynamo_object['archive_id'] }])
    end
  end

  describe '#status' do
    let(:recording) { described_class.new(object: dynamo_object, user_id: 1) }

    it 'returns the status if defined in the dynamo object' do
      dynamo_object['status'] = 'available'

      expect(recording.status).to eq dynamo_object['status']
    end

    it 'does not raise an error if the status key is not defined in the dynamo object' do
      expect { recording.status }.not_to raise_error
    end

    it 'returns nil when there is no status key defined in the dynamo object' do
      expect(recording.status).to be_nil
    end
  end

  describe '#user_info' do
    it 'returns the expected user information for the user id specified at initialization time' do
      recording1 = described_class.new(object: dynamo_object, user_id: 1)
      recording2 = described_class.new(object: dynamo_object, user_id: 2)

      expect(recording1.user_info).to eq user_1
      expect(recording2.user_info).to eq user_2
    end

    it 'returns nil if the specified user id is not present in the dynamo object' do
      recording = described_class.new(object: dynamo_object, user_id: 3)

      expect(recording.user_info).to be_nil
    end
  end

  describe '#available?' do
    let(:recording) { described_class.new(object: dynamo_object, user_id: 1) }

    it 'returns true if the status is "available"' do
      dynamo_object['status'] = 'available'

      expect(recording).to be_available
    end

    it 'returns false otherwise' do
      dynamo_object['status'] = 'error'

      expect(recording).not_to be_available
    end
  end

  describe '#error?' do
    let(:recording) { described_class.new(object: dynamo_object, user_id: 1) }

    it 'returns true if the status is "error"' do
      dynamo_object['status'] = 'error'

      expect(recording.error?).to be true
    end

    it 'returns false otherwise' do
      dynamo_object['status'] = 'available'

      expect(recording.error?).to be false
    end
  end

  describe '#stopped?' do
    let(:recording) { described_class.new(object: dynamo_object, user_id: 1) }

    it 'returns true if the status is "stopped"' do
      dynamo_object['status'] = 'stopped'

      expect(recording).to be_stopped
    end

    it 'returns false otherwise' do
      dynamo_object['status'] = 'available'

      expect(recording).not_to be_stopped
    end
  end

  describe '#video_path' do
    let(:recording) { described_class.new(object: dynamo_object, user_id: 1) }

    it 'returns the relative path to the recording using the specified formad' do
      expect(recording.video_path(format: 'mp4')).to eq user_1['video']['video/mp4']
      expect(recording.video_path(format: 'webm')).to eq user_1['video']['video/webm']
    end

    it 'does return nothing when the specified format is not present' do
      expect(recording.video_path(format: 'ogg')).to be_nil
    end
  end

  describe '#to_json' do
    it 'returns a serialized object with a "path" key that contains the user video path' do
      recording1 = described_class.new(object: dynamo_object, user_id: 1)
      recording2 = described_class.new(object: dynamo_object, user_id: 2)

      response1 = recording1.to_json
      response2 = recording2.to_json

      expect(JSON.parse(response1)).to eq(dynamo_object.merge('path' => user_1['video']))
      expect(JSON.parse(response2)).to eq(dynamo_object.merge('path' => user_2['video']))
    end
  end

  describe '#method_missing' do
    let(:recording) { described_class.new(object: dynamo_object, user_id: 1) }

    context 'when the method name corresponds to one of the keys of the dynamo object' do
      it 'returns its value' do
        expect(recording.course_id).to eq dynamo_object['course_id']
        expect(recording.archive_id).to eq dynamo_object['archive_id']
      end
    end

    context 'when the method name does not corresponds to a key of the dynamo object' do
      it 'raises an error if it is not defined by the described class' do
        expect { recording.im_not_defined! }.to raise_error(NoMethodError)
      end
    end
  end
end
