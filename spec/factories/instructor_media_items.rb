FactoryBot.define do
  factory :instructor_media_item do
    instructor_id { 1 }
    media_type { 'image' }
    original_filename { 'foo.txt' }
    size { 1 }
    width { 1 }
    height { 1 }
    extname { '.jpg' }
  end
end
