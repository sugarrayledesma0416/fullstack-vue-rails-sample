FactoryBot.define do
  factory :cartridge_line_item_destination, class: Cartridge::LineItemDestination do |lid|
    lid.association :user
    lid.association :section
    lid.association :activity
    lid.line_item_url { "https://lms.example.org/api/lti/courses/#{SecureRandom.uuid}/line_item/#{rand(1..99)}" }
  end
end
