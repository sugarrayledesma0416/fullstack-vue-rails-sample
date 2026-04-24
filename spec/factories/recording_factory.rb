FactoryBot.define do
  factory :recording do
    user
    created_at      { Date.today }
    recording_path  { 'recording_path' }
    uuid            { 'f25c1e93-50c8-4113-a0a5-9b6966caf42f' }
  end

  factory :video_recording, class: VideoRecording do
    user
    created_at      { Date.today }
    recording_path  { 'recording_path' }
    uuid            { 'f25c1e93-50c8-4113-a0a5-9b6966caf42f' }
  end
end
