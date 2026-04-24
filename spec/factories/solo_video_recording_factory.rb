FactoryBot.define do
  factory :solo_video_recording do
    user
    activity
    recording_path { 'fake/solo/recording/path' }
  end
end
