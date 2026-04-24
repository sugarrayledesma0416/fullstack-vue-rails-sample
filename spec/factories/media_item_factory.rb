FactoryBot.define do
  factory :media_item do
    media_type { 'audio' }
    filename { 'filename' }
  end

  factory :media_item_audio, class: :media_item do
    media_type { 'audio' }
    filename { 'audio_filename' }
  end

  factory :media_item_audio_transcript, parent: :media_item_audio do
    transcript { 'foo bar' }
  end

  factory :media_item_video, class: :media_item do
    media_type { 'video' }
    filename { 'video_filename' }
  end

  factory :media_item_image, class: :media_item do
    media_type { 'image' }
    filename { 'image_filename' }
    alt_tag { 'spec image' }
  end

  factory :diagnostic_ref_media_item, parent: :media_item_image do
    height { 32 }
    width { 40 }
  end

  factory :media_item_subtitle, class: :media_item do
    media_type { 'subtitle' }
    filename { 'subtitle_filename' }
  end
end
