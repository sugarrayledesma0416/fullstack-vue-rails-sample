FactoryBot.define do
  factory :e_reader_item do
    guid { SecureRandom.uuid }
    concept
    sequence(:title) { |index| "Title #{index}" }
    sequence(:page_section) { |index| "Page Section #{index}" }
    sequence(:descriptor) { |index| "Descriptor #{index}" }
    page_number { SecureRandom.random_number(1..500) }
  end
end

