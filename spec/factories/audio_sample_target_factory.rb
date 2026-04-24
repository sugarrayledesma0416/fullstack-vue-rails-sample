FactoryBot.define do
  factory :audio_sample_target do
    sequence(:dictionary_id) { |index| index }
    sequence(:word) { |index| "word #{index}" }
    batch_name { 'batch 1' }
    sequence(:audio_file) { |index| "/path/to/audio_#{index}.mp3" }
    samples_desired { 3 }
  end
end
