FactoryBot.define do
  factory :forum do
    sequence(:name) { |index| "Forum #{index}" }
    section
    instructor
  end
end
