FactoryBot.define do
  factory :track_group do
    program
    concept
    lesson
    group_set
    name { 'Learn' }
    how_to_use { 'How to Use' }
  end
end
