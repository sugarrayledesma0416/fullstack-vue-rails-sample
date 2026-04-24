FactoryBot.define do
  factory :default_vocabulary_word do
    lesson
    program
    audio_paths { ['foo.mp3', 'bar.mp3'] }
    sequence(:composite_dictionary_id) { |n| "#{n}:#{n + 1}:#{n + 2}" }
    definition { 'a passport' }
    target { 'pasaporte' }
    topic { 'Travel' }
    translation { 'passport' }
  end
end
